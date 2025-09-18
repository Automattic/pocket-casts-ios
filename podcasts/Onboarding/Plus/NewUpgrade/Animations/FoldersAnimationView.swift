import Foundation
import SwiftUI

fileprivate struct FolderPodcastAnimationInfo {
    let name: String
    let image1: String
    let image2: String
    let image3: String
    let image4: String
    let color: Color
    let focus: Bool
    let scalePoint: UnitPoint
}

fileprivate struct FolderPodcastImage: View {
    let image: String
    let size: CGFloat

    var body: some View {
        Image(image)
            .resizable(resizingMode: .stretch)
            .frame(width: size, height: size)
            .aspectRatio(contentMode: .fit)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
    }
}

fileprivate struct FolderPodcastAnimation: View {

    let folder: FolderPodcastAnimationInfo

    @EnvironmentObject var theme: Theme

    static let originalSize: Double = CGFloat(100)

    @State private var animationProgress = CGFloat(0)
    @State private var size = CGFloat(originalSize)
    @State private var unFocusOpacity: Double = 1
    @State private var scale: Double = 1
    @State private var offset = CGFloat(0)

    var body: some View {
        VStack(alignment: .center, spacing: 18 * animationProgress) {
            Grid(horizontalSpacing: 10 - (animationProgress * 5), verticalSpacing: 10 - (animationProgress * 5)) {
                GridRow {
                    FolderPodcastImage(image: folder.image1, size: size)
                    FolderPodcastImage(image: folder.image2, size: size)
                }
                GridRow {
                    FolderPodcastImage(image: folder.image3, size: size)
                    FolderPodcastImage(image: folder.image4, size: size)
                }
            }
            if animationProgress > 0 {
                Text(folder.name)
                    .font(size: 19, style: .title2, weight: .bold)
                    .foregroundStyle(.white)
                    .opacity(animationProgress * 1)
            }
        }
        .padding(.vertical, 16 * animationProgress)
        .padding(.horizontal, 28 * animationProgress)
        .frame(
            width: 210,
            height: 210
        )
        .background(
            ZStack {
                Rectangle()
                    .foregroundStyle(folder.color)
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: .black.opacity(0), location: 0.00),
                        Gradient.Stop(color: .black.opacity(0.2), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
            }
            .opacity(folder.focus ? animationProgress * 1 : animationProgress * unFocusOpacity * 3)
        )
        .cornerRadius(animationProgress > 0.7 ? 30 * animationProgress : 0)
        .onAppear {
            animate()
        }
        .opacity(folder.focus ? 1 : unFocusOpacity)
        .scaleEffect(folder.focus ? 1 : scale, anchor: folder.scalePoint)
        .offset(x: 0, y: folder.focus ? 0 : offset)
    }

    private func animate() {
        animationProgress = 0
        unFocusOpacity = 1
        size = Self.originalSize
        // Focus animation
        withAnimation(.easeInOut(duration: 1).delay(2)) {
            animationProgress = 1
            size = 70
        }
        // Unfocus animation
        withAnimation(.easeInOut(duration: 0.5).delay(2)) {
            unFocusOpacity = 0
        }
        withAnimation(.easeInOut(duration: 0.1).delay(2.5)) {
            scale = 0.5
            offset = 20
        }
        withAnimation(.easeInOut(duration: 0.5).delay(3)) {
            unFocusOpacity = 0.3
            offset = 0
        }
    }
}

struct FoldersAnimationView: View {

    fileprivate let folders: [FolderPodcastAnimationInfo] = { [
        .init(name: "Books", image1: "login-cover-2", image2: "login-cover-10", image3: "login-cover-5", image4: "login-cover-6", color: Color(hex: "#9BA2FF"), focus: false, scalePoint: .topTrailing),
        .init(name: "Favorites", image1: "login-cover-9", image2: "login-cover-4", image3: "login-cover-7", image4: "login-cover-8", color: Color(hex: "#1AB8FF"), focus: true, scalePoint: .center),
        .init(name: "Games", image1: "login-cover-3", image2: "login-cover-2", image3: "login-cover-9", image4: "login-cover-5", color: Color(hex: "#32D9A9"), focus: false, scalePoint: .bottomLeading),
    ] }()

    @EnvironmentObject var theme: Theme

    @State private var animationProgress = CGFloat(0)

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(Array(zip(folders.indices, folders)), id: \.0) { (index, folder) in
                        FolderPodcastAnimation(folder: folder)
                        Spacer().frame(width: (animationProgress * 20) + 10)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: geometry.size.width)
        }
        .frame(minHeight: 210)
        .onAppear() {
            animate()
        }
    }

    private func animate() {
        animationProgress = 0
        withAnimation(.easeInOut(duration: 1).delay(2)) {
            animationProgress = 1
        }
    }

}

#Preview {
    HStack {
        Spacer()
        VStack(alignment: .leading) {
            Spacer()
            FoldersAnimationView().setupDefaultEnvironment()
            Spacer()
        }
        Spacer()
    }
}
