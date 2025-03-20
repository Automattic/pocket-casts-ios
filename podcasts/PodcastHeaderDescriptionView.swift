import SwiftUI
@preconcurrency import WebKit

struct PodcastHeaderDescriptionView: UIViewRepresentable {
    @State var htmlDescription: String
    weak var delegate: ExpandableLabelDelegate?
    //var heightChanged: (CGFloat) -> ()
    @Binding var contentHeight: CGFloat

    static var cache: [String: RichExpandableLabel] = [:]

    init(htmlDescription: String, contentHeight: Binding<CGFloat>) {
        _htmlDescription = .init(initialValue: htmlDescription)
        _contentHeight = contentHeight
    }

    func makeUIView(context: Context) -> RichExpandableLabel {
        if let view = Self.cache[htmlDescription] {
            view.removeFromSuperview()
            context.coordinator.webView = view
            return view
        }
        let view = RichExpandableLabel()
        Self.cache.removeAll()
        Self.cache[htmlDescription] = view
        // we need this or else the webview will not expand to the width
        view.translatesAutoresizingMaskIntoConstraints = true
        context.coordinator.webView = view
        return view
    }

    func updateUIView(_ uiView: RichExpandableLabel, context: Context) {
        uiView.setRichText(html: htmlDescription)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ExpandableLabelDelegate {
        func willExpandLabel(_ label: UIView) {

        }

        func didExpandLabel(_ label: UIView) {

        }

        func willCollapseLabel(_ label: UIView) {

        }

        func didCollapseLabel(_ label: UIView) {

        }

        func linkTapped(url: URL) {

        }

        func heightChanged(newHeight: CGFloat) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.contentHeight = newHeight
            }
        }

        var parent: PodcastHeaderDescriptionView
        var webView: RichExpandableLabel? {
            didSet {
                webView?.delegate = self
            }
        }

        init(_ parent: PodcastHeaderDescriptionView) {
            self.parent = parent
        }
    }

}
