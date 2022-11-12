import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var theme: Theme

    enum DisplayState {
        case plus
        case newAccount
    }

    let displayState: DisplayState = .plus

    var titleText: String {
        switch displayState {
        case .plus:
            return "Thank you, now let’s get you listening!"
        case .newAccount:
            return "Welcome, now let’s get you listening!"
        }
    }

    var iconName: String {
        switch displayState {
        case .plus:
            return "welcome-icon"
        case .newAccount:
            return "welcome-icon"
        }
    }

    var iconColor: Color {
        switch displayState {
        case .plus:
            return Color.plusGradientColor1
        case .newAccount:
            return AppTheme.color(for: .primaryIcon01, theme: theme)
        }
    }
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                switch displayState {
                case .plus:
                    PlusIconConfetti(frame: proxy.frame(in: .global))

                case .newAccount:
                    WelcomeConfetti(frame: proxy.frame(in: .global))

                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .ignoresSafeArea().zIndex(100)

            ScrollViewIfNeeded {
                VStack(alignment: .leading) {
                    HStack {
                        ZStack {
                            Image(iconName)
                                .foregroundColor(iconColor)
                                .gradientOverlay(displayState == .plus ? Color.plusGradient : nil)
                            Image("welcome-icon-check")
                        }
                        Spacer()
                    }

                    Text(titleText)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .font(size: 31, style: .title, weight: .bold)

                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Import your podcasts")
                                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                        .font(size: 18, style: .body, weight: .semibold)
                                    Text("Coming from another app? Bring your podcasts with you.")
                                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                        .font(size: 13, style: .footnote)
                                }
                                Spacer()
                                Image("welcome-import")
                                    .foregroundColor(AppTheme.color(for: .primaryIcon01, theme: theme))

                            }.padding(24)

                            Divider().background(AppTheme.color(for: .primaryUi05, theme: theme))

                            Button("Import Podcasts") {

                            }
                            .foregroundColor(AppTheme.color(for: .primaryInteractive01, theme: theme))
                            .font(size: 15, style: .callout, weight: .medium)
                            .padding([.top, .bottom], 16)
                            .padding([.leading, .trailing], 24)
                        }

                    }.overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(AppTheme.color(for: .primaryUi05, theme: theme), lineWidth: 1)
                    )

                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Discover something new")
                                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                        .font(size: 18, style: .body, weight: .semibold)
                                    Text("Find under-the-radar and trending podcasts in our hand-curated Discover page.")
                                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                        .font(size: 13, style: .footnote)
                                }
                                Spacer()
                                Image("welcome-discover")
                                    .foregroundColor(AppTheme.color(for: .primaryIcon01, theme: theme))
                            }.padding(24)

                            Divider().background(AppTheme.color(for: .primaryUi05, theme: theme))

                            Button("Find My Next Podcast") {

                            }
                            .foregroundColor(AppTheme.color(for: .primaryInteractive01, theme: theme))
                            .font(size: 15, style: .callout, weight: .medium)
                            .padding([.top, .bottom], 16)
                            .padding([.leading, .trailing], 24)
                        }

                    }.overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(AppTheme.color(for: .primaryUi05, theme: theme), lineWidth: 1)
                    ).padding(.top, 16)

                    Spacer()

                    Button("Done") {

                    }.buttonStyle(RoundedButtonStyle())
                }
            }
            .padding(.top, 70)
            .padding([.leading, .trailing], 24)
            .padding(.bottom)
            .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .previewWithAllThemes()
    }
}

// MARK: - Confetti 🎉

struct PlusIconConfetti: UIViewRepresentable {
    let frame: CGRect

    func makeUIView(context: Context) -> UIView {
        let hostView = UIView(frame: frame)

        PlusConfettiView.cleanupAndAnimate(on: hostView, frame: frame) { confettiView in
            confettiView.removeFromSuperview()
        }

        return hostView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    private class PlusConfettiView: ConfettiView {
        override func emitConfetti() {
            guard let icon = UIImage(named: "confetti-plus") else {
                return
            }

            // Add more to the emitter
            var particles: [Particle] = []
            for _ in 0..<10 {
                particles.append(Particle(image: icon))
            }

            var config = PlusConfettiView.EmitterConfig()
            config.scaleRange = 1.2
    //        config.spinRange = 0

            self.emit(with: particles, config: config)
        }
    }
}

struct WelcomeConfetti: UIViewRepresentable {
    let frame: CGRect

    func makeUIView(context: Context) -> UIView {
        let hostView = UIView(frame: frame)
        NormalConfettiView.cleanupAndAnimate(on: hostView, frame: frame) { confettiView in
            confettiView.removeFromSuperview()
        }

        return hostView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    private class NormalConfettiView: ConfettiView {
        override func emitConfetti() {
            var images: [Particle] = []

            // Generate the particles
            for i in 1..<21 {
                let fileName = "confetti-shape-\(i)"
                if let image = UIImage(named: fileName) {
                    images.append(Particle(image: image))
                }
            }

            self.emit(with: images, config: NormalConfettiView.EmitterConfig())
        }
    }
}
