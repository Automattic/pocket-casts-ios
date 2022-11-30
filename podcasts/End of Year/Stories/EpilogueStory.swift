import SwiftUI

struct EpilogueStory: StoryView {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    var duration: TimeInterval = 5.seconds

    var identifier: String = "epilogue"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UIColor(hex: "#1A1A1A").color
                    .allowsHitTesting(false)

                VStack {
                    VStack {
                        Image("heart")
                            .padding(.bottom, 20)

                        Text(L10n.eoyStoryEpilogueTitle.replacingOccurrences(of: "Pocket Casts", with: "Pocket\u{00a0}Casts"))
                            .foregroundColor(.white)
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                            .padding(.bottom)
                        Text(L10n.eoyStoryEpilogueSubtitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.1)
                            .minimumScaleFactor(0.01)
                            .opacity(0.8)
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .allowsHitTesting(false)

                    Button(action: {
                        StoriesController.shared.replay()
                        Analytics.track(.endOfYearStoryReplayButtonTapped)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(UIColor(hex: "#1A1A1A").color)
                            Text(L10n.eoyStoryReplay)
                                .foregroundColor(UIColor(hex: "#1A1A1A").color)
                                .font(.system(size: 20, weight: .bold))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.01)
                        }
                    }
                    .buttonStyle(ReplayButtonStyle())
                    .padding(.top, 20)
                    .opacity(renderForSharing ? 0 : 1)
                }
                .padding()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("logo_white")
                        .padding(.bottom, 40)
                    Spacer()
                }
            }
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }
}

struct ReplayButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .hidden()
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.white)
            )
            .overlay(configuration.label)
    }
}

struct EpilogueStory_Previews: PreviewProvider {
    static var previews: some View {
        EpilogueStory()
    }
}
