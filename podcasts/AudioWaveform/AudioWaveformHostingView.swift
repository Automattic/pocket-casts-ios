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

    var secondaryColor: UIColor = UIColor.gray.withAlphaComponent(0.5) {
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

        let waveformView = PlayerAudioWaveformView(
            audioMeter: audioMeter,
            barCount: 40,
            barWidth: 4,
            barSpacing: 4,
            primaryColor: Color(primaryColor),
            secondaryColor: Color(secondaryColor)
        )

        let hostingController = UIHostingController(rootView: waveformView)
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

    private func updateColors() {
        // Recreate the view with new colors
        hostingController?.view.removeFromSuperview()

        let waveformView = PlayerAudioWaveformView(
            audioMeter: audioMeter,
            barCount: 40,
            barWidth: 4,
            barSpacing: 4,
            primaryColor: Color(primaryColor),
            secondaryColor: Color(secondaryColor)
        )

        let newHostingController = UIHostingController(rootView: waveformView)
        newHostingController.view.backgroundColor = .clear
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(newHostingController.view)

        NSLayoutConstraint.activate([
            newHostingController.view.topAnchor.constraint(equalTo: topAnchor),
            newHostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            newHostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = newHostingController
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
