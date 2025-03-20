import SwiftUI
@preconcurrency import WebKit

struct PodcastHeaderDescriptionView: UIViewRepresentable {
    @State var htmlDescription: String
    weak var delegate: ExpandableLabelDelegate?
    var heightChanged: (CGFloat) -> ()

    static var cache: [String: RichExpandableLabel] = [:]

    init(htmlDescription: String, delegate: ExpandableLabelDelegate?, heightChanged: @escaping (CGFloat) -> ()) {
        _htmlDescription = .init(initialValue: htmlDescription)
        self.delegate = delegate
        self.heightChanged = heightChanged
    }

    func makeUIView(context: Context) -> RichExpandableLabel {
        if let view = Self.cache[htmlDescription] {
            view.removeFromSuperview()
            view.delegate = self.delegate
            context.coordinator.webView = view
            return view
        }
        let view = RichExpandableLabel()
        Self.cache.removeAll()
        Self.cache[htmlDescription] = view
        // we need this or else the webview will not expand to the width
        view.translatesAutoresizingMaskIntoConstraints = true
        view.delegate = self.delegate
        context.coordinator.webView = view
        return view
    }

    func updateUIView(_ uiView: RichExpandableLabel, context: Context) {
        context.coordinator.parent = self
        if uiView.previousHTML != htmlDescription {
            uiView.setRichText(html: htmlDescription)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {

        func heightChanged(newHeight: CGFloat) {
            DispatchQueue.main.async { [weak self] in       
                self?.parent.heightChanged(newHeight)
            }
        }

        var parent: PodcastHeaderDescriptionView
        weak var webView: RichExpandableLabel? {
            didSet {
                webView?.delegate = parent.delegate
                webView?.heightChanged = self.heightChanged
            }
        }

        init(_ parent: PodcastHeaderDescriptionView) {
            self.parent = parent
        }
    }

}
