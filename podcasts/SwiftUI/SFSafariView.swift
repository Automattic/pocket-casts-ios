import SafariServices
import SwiftUI

struct SFSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariView>) {
        // No need to do anything here
    }
}

struct SFSafariViewModifier: ViewModifier {
    @State private var presentationState: URLPresentationState = .notPresented

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { incomingURL in
                presentationState = .presenting(incomingURL)
                return .handled
            })
            .sheet(isPresented: Binding(
                get: { presentationState != .notPresented },
                set: { if !$0 { presentationState = .notPresented } }
            )) {
                if case .presenting(let url) = presentationState {
                    SFSafariView(url: url)
                        .onAppear {
                            print("Opening URL: \(url)")
                        }
                }
            }
    }

    enum URLPresentationState: Equatable {
        case notPresented
        case presenting(URL)
    }
}

extension View {
    /// Handles all `OpenURLAction` events from `EnvironmentValues.openURL` with `SFSafariView` (a SwiftUI wrapper for`SafariViewController`).
    func handleURLsWithSFSafariView() -> some View {
        self.modifier(SFSafariViewModifier())
    }
}
