import SwiftUI
import PocketCastsDataModel

struct TopListenedCategories: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.purple

                VStack {
                    Text("Your Top Categories")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom)

                    VStack {
                        VStack {
                            ZStack {
                                VStack {
                                    Image("square_perspective")
                                        .renderingMode(.template)
                                        .foregroundColor(.red)
                                }

                                let values: [CGFloat] = [1, 0, 0.50, 1, 0, 0]
                                VStack {
                                    Text("8")
                                        .foregroundColor(.white)
                                        .padding(.leading, -8)
                                }
                                .transformEffect(CGAffineTransform(
                                    a: values[0], b: values[1],
                                    c: values[2], d: values[3],
                                    tx: 0, ty: 0
                                ))
                                .rotationEffect(.init(degrees: -30))
                            }
                        }
                        .zIndex(1)

                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.red, .black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                            .padding(.top, -39)
                            .frame(height: 200)
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    VStack {
                        ForEach(0 ..< min(listenedCategories.count, 5), id: \.self) { x in
                            HStack(spacing: 16) {
                                Text("\(x + 1).")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                Image("discover_cat_1")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                                Text(listenedCategories[x].categoryTitle.localized)
                                    .lineLimit(2)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                VStack(alignment: .trailing) {
                                    Text("\(listenedCategories[x].numberOfPodcasts)").font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Podcasts")
                                        .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                }
            }
        }
    }
}

struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategories(listenedCategories: [])
    }
}
