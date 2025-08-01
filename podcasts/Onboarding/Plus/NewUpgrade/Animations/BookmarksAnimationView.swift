import Foundation
import SwiftUI

fileprivate struct BookmarkUpgradeAnimation {
    let image: String
    let title: String
    let time: String
    let rotationStart: Double
    let rotationEnd: Double
    let gradientStart: Color
    let gradientEnd: Color
}

fileprivate struct BookmarkUpgradeRow: View {

    let bookmark: BookmarkUpgradeAnimation
    let index: Int

    @EnvironmentObject var theme: Theme

    @State private var rotation = Angle(degrees: 0.0)
    @State private var opacity = 0.0
    @State private var selected = true
    @State private var scale: CGFloat = 2.0

    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            Image(bookmark.image)
                .resizable()
                .frame(width: 78, height: 78)
                .cornerRadius(8)
            Text(bookmark.title)
                .font(size: 16, style: .body, weight: .medium)
                .kerning(0.36)
                .foregroundStyle(.white)
            HStack {
                Text(bookmark.time)
                    .font(size: 16, style: .body, weight: .medium)
                    .foregroundStyle(.black)
                Image("bookmarks-icon-play")
                    .renderingMode(.template)
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white)
            }
        }
        .padding(.vertical, 24)
        .frame(width: 180, height: 180)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: bookmark.gradientStart, location: 0.00),
                    Gradient.Stop(color: bookmark.gradientEnd, location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.85, y: 0.94),
                endPoint: UnitPoint(x: 0.18, y: 0.06)
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 2)
        .rotationEffect(rotation)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            animate(Double(index))
        }
    }

    private func animate(_ index: Double) {
        rotation = Angle(degrees: bookmark.rotationStart)
        opacity = 0
        withAnimation(.easeInOut(duration: 0.8).delay(0.1 + (0.9 * index))) {
            rotation = Angle(degrees: bookmark.rotationEnd)
            opacity = 1
            scale = 1
        }
    }
}

struct BookmarksAnimationView: View {

    fileprivate let bookmarks: [BookmarkUpgradeAnimation] = [
        .init(image: "login-cover-9", title: "Amazing quote!", time: "19:05", rotationStart: 9.5, rotationEnd: -2.5, gradientStart: Color(hex: "#E4D820"), gradientEnd: Color(hex: "#E8A92C")),
        .init(image: "login-cover-10", title: "This bit cracks me up", time: "23:10", rotationStart: 12, rotationEnd: 7, gradientStart: Color(hex: "#EC4034"), gradientEnd: Color(hex: "#FF9D00")),
        .init(image: "login-cover-2", title: "Love this part!", time: "6:45", rotationStart: 5, rotationEnd: -5, gradientStart: Color(hex: "#0202FE"), gradientEnd: Color(hex: "#27D9E9")),
    ]

    @EnvironmentObject var theme: Theme

    var body: some View {
        ZStack {
            ForEach(Array(zip(bookmarks.indices, bookmarks)), id: \.0) { (index, bookmark) in
                BookmarkUpgradeRow(bookmark: bookmark, index: index).zIndex(Double(index) * 0.1)
            }
        }
        .padding(.horizontal, 16)
    }

}

#Preview {
    BookmarksAnimationView().setupDefaultEnvironment()
}
