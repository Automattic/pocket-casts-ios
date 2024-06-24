import Foundation
import UIKit

class TranscriptsViewController: PlayerItemViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateColors()
        loadTranscript()
    }

    private func setupViews() {
        view.addSubview(transcriptView)

        NSLayoutConstraint.activate(
            [
                transcriptView.topAnchor.constraint(equalTo: view.topAnchor),
                transcriptView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                transcriptView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                transcriptView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
    }

    private lazy var transcriptView: UITextView = {
        let textView =  UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        return textView
    }()

    override func willBeAddedToPlayer() {
        updateColors()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
    }

    override func themeDidChange() {
        updateColors()
    }

    private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        transcriptView.backgroundColor =  PlayerColorHelper.playerBackgroundColor01()
    }

    private func loadTranscript() {
        
    }
}
