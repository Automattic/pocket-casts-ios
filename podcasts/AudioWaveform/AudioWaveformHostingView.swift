import UIKit
import SwiftUI

/// A UIView wrapper for the PlayerAudioWaveformView SwiftUI view
class AudioWaveformHostingView: UIView {

    private var hostingController: UIHostingController<PlayerAudioWaveformView>?
    private let audioMeter = AudioMeterManager.shared

    var primaryColor: UIColor = .white {
        didSet {
            updateColors()
        }
    }

    var secondaryColor = UIColor.gray.withAlphaComponent(0.5) {
        didSet {
            updateColors()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        let hostingController = UIHostingController(rootView: makeWaveformView())
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.hostingController = hostingController
    }

    private func makeWaveformView() -> PlayerAudioWaveformView {
        PlayerAudioWaveformView(
            audioMeter: audioMeter,
            barCount: 40,
            barWidth: 4,
            barSpacing: 4,
            primaryColor: Color(primaryColor),
            secondaryColor: Color(secondaryColor)
        )
    }

    private func updateColors() {
        // Swap the root view in place rather than rebuilding the hosting controller.
        hostingController?.rootView = makeWaveformView()
    }

    /// Start the audio metering and animation
    func startWaveform() {
        audioMeter.startMetering()
    }

    /// Stop the audio metering and animation
    func stopWaveform() {
        audioMeter.stopMetering()
    }
}
