import SwiftUI
import PocketCastsServer

@MainActor
class ReferralSendPassModel: ObservableObject {
    let offerInfo: ReferralsOfferInfo
    @Published var referralURL: URL?
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    @Published var isLoading: Bool = false

    init(offerInfo: ReferralsOfferInfo, onShareGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.offerInfo = offerInfo
        self.onShareGuestPassTap = onShareGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var title: String {
        L10n.referralsTipMessage(offerInfo.localizedOfferDurationNoun)
    }

    var buttonTitle: String {
        L10n.referralsShareGuestPass
    }

    var shareText: String {
        L10n.referralsSharePassMessage(self.offerInfo.localizedOfferDurationAdjective)
    }

    var shareSubject: String {
        L10n.referralsSharePassSubject(self.offerInfo.localizedOfferDurationAdjective)
    }

    func loadData() async {
        isLoading = true
        let code = await ApiServerHandler.shared.getReferralCode()
        if let code {
            referralURL = URL(string: code.url)
        }
        isLoading = false
    }
}

struct ReferralSendPassView: View {
    @StateObject var viewModel: ReferralSendPassModel

    @State var showShareView: Bool = false

    @ViewBuilder
    var loadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            }
            Spacer()
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else {
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.onCloseTap?()
                        }, label: {
                            Image("close").foregroundColor(Color.white)
                        })
                        Spacer()
                    }
                    VStack(spacing: Constants.verticalSpacing) {
                        SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                        Text(viewModel.title)
                            .font(size: 31, style: .title, weight: .bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        ZStack {
                            ForEach(0..<Constants.numberOfPasses, id: \.self) { i in
                                ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
                                    .frame(width: Constants.defaultCardSize.width - (CGFloat(Constants.numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                                    .offset(CGSize(width: 0, height: CGFloat(Constants.numberOfPasses * i) * Constants.cardInset.height))
                            }
                        }
                    }
                    Spacer()
                    Button(viewModel.buttonTitle) {
                        viewModel.onShareGuestPassTap?()
                    }
                    .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
                }
            }
        }
        .padding()
        .background(.black)
        .task {
            await viewModel.loadData()
        }
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = ReferralCardView.Constants.defaultCardSize
        static let cardInset = CGSize(width: 40, height: 5)
        static let numberOfPasses: Int = 3
    }
}

#Preview("With Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerInfo: ReferralsOfferInfoMock()))
    }
}
