import Combine
import PocketCastsUtils
import Foundation

class MessageSupportViewModel: ObservableObject {
    public enum Completion: Identifiable {
        case success
        case failure(error: Error)

        var id: Int {
            switch self {
            case .success: return 0
            case .failure: return 1
            }
        }
    }

    public enum MessageSupportFailure: Error {
        case watchLogMissing
    }

    // MARK: Input

    @Published var requesterName: String
    @Published var requesterEmail: String
    @Published var comment: String

    // MARK: Output

    @Published var isValid = false
    @Published var isWorking = false
    @Published var completion: Completion? = nil

    // MARK: Error Handling

    @Published var requesterNameErrored: Bool = false
    @Published var requesterEmailErrored: Bool = false
    @Published var commentErrored: Bool = false

    var title: String {
        config.isFeedback ? L10n.supportFeedback : L10n.support
    }

    let attachedLogsView: SupportLogsView
    let config: ZDConfig

    // MARK: Private vars

    private var cancellables = Set<AnyCancellable>()
    private let supportService: ZendeskSupportService

    // MARK: Input Checkers

    private let typingDebounceTiming: RunLoop.SchedulerTimeType.Stride = 0.2
    private var isNameValid: AnyPublisher<Bool, Never> {
        $requesterName
            .debounce(for: typingDebounceTiming, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { input in
                input.count >= 1
            }
            .eraseToAnyPublisher()
    }

    private var isEmailValid: AnyPublisher<Bool, Never> {
        $requesterEmail
            .debounce(for: typingDebounceTiming, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { input in
                input.isValidEmail
            }
            .eraseToAnyPublisher()
    }

    private var isCommentValid: AnyPublisher<Bool, Never> {
        $comment
            .debounce(for: typingDebounceTiming, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { input in
                input.trim().count >= 3 // Loose check to make sure the box has some text.
            }
            .eraseToAnyPublisher()
    }

    private var isFormValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4(isNameValid, isEmailValid, isCommentValid, $isWorking)
            .map { nameIsValid, emailIsValid, commentIsValid, isWorking in
                nameIsValid && emailIsValid && commentIsValid && !isWorking
            }
            .eraseToAnyPublisher()
    }

    // MARK: Init

    init(config: ZDConfig, requesterName: String = "", requesterEmail: String = "", comment: String = "", session: URLSession = URLSession.shared) {
        self.config = config
        self.requesterName = requesterName
        self.requesterEmail = requesterEmail
        self.comment = comment
        attachedLogsView = SupportLogsView(SupportLogsViewModel(config))

        supportService = ZendeskSupportService(config: config, session: session)

        isNameValid
            .dropFirst()
            .receive(on: RunLoop.main)
            .map { !$0 }
            .assign(to: &$requesterNameErrored)

        isEmailValid
            .dropFirst()
            .receive(on: RunLoop.main)
            .map { !$0 }
            .assign(to: &$requesterEmailErrored)

        isCommentValid
            .dropFirst()
            .receive(on: RunLoop.main)
            .map { !$0 }
            .assign(to: &$commentErrored)

        isFormValid
            .receive(on: RunLoop.main)
            .assign(to: &$isValid)
    }

    // MARK: Events

    open func submitRequest(ignoreUnavailableWatchLogs: Bool = false) {
        isWorking.toggle()

        config.customFields(forDisplay: false, optOut: UserDefaults.standard.debugOptedOut)
            .flatMap { [unowned self] customFields -> AnyPublisher<String, Error> in

                // Check if the user mentioned watch on their issue description and if there
                // are any Apple Watch logs available.
                let containsWatch = self.comment.localizedCaseInsensitiveContains(L10n.watch) || self.comment.lowercased().contains("watch")
                if containsWatch && customFields.first(where: { $0.value.contains(FileLog.noWearableLogsAvailable) }) != nil && !ignoreUnavailableWatchLogs {
                    return Fail(error: MessageSupportFailure.watchLogMissing).eraseToAnyPublisher()
                } else {
                    let requestObject = ZDSupportRequest(subject: self.config.subject,
                                                         name: self.requesterName,
                                                         email: self.requesterEmail,
                                                         comment: self.comment,
                                                         customFields: customFields,
                                                         tags: self.config.tags)

                    return self.supportService.submitSupportRequest(requestObject)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                isWorking.toggle()
                switch completion {
                case let .failure(error):
                    self.completion = .failure(error: error)
                case .finished:
                    self.completion = .success
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
