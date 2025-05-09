import SwiftUI
@preconcurrency import WebKit

struct PodcastHeaderDescriptionView: UIViewRepresentable {
    @State var htmlDescription: String
    weak var delegate: ExpandableLabelDelegate?
    var heightChanged: (CGFloat) -> ()

    init(htmlDescription: String, delegate: ExpandableLabelDelegate?, heightChanged: @escaping (CGFloat) -> ()) {
        _htmlDescription = .init(initialValue: htmlDescription)
        self.delegate = delegate
        self.heightChanged = heightChanged
    }

    func makeUIView(context: Context) -> RichExpandableLabel {
        let view = RichExpandableLabel()
        // we need this or else the webview will not expand to the width
        view.translatesAutoresizingMaskIntoConstraints = true
        view.delegate = self.delegate
        view.heightChanged = self.heightChanged
        return view
    }

    func updateUIView(_ uiView: RichExpandableLabel, context: Context) {
        if uiView.previousHTML != htmlDescription {
            uiView.setRichText(html: htmlDescription)
        }
    }
}
