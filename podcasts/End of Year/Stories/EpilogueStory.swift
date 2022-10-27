import SwiftUI

struct EpilogueStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(backgroundColor: UIColor(hex: "#FDDC68").color, foregroundColor: UIColor(hex: "#D29D41").color)
                    .allowsHitTesting(false)

                VStack {
                    Text(L10n.eoyStoryEpilogueTitle)
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)
                    Text(L10n.eoyStoryEpilogueSubtitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.1)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                    Button(action: {
                        StoriesController.shared.replay()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text(L10n.eoyStoryReplay)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxHeight: geometry.size.height * 0.12)
                                .minimumScaleFactor(0.01)
                            Spacer()
                        }
                    }
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
}

struct EpilogueStory_Previews: PreviewProvider {
    static var previews: some View {
        EpilogueStory()
    }
}
