import UIKit
import SwiftUI

struct MarqueeTextView: View {
    let words: [String]
    let separator: Image
    private(set) var separatorPadding: Double = 0 // Must be mutable for initializer
    let direction: HorizontalEdge

    @State private var offset = CGFloat.zero
    @State private var screenWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 0

    var font: UIFont {
        return UIFont(name: "Humane-Medium", size: 227) ?? UIFont.systemFont(ofSize: 227)
    }

    var textVerticalOffset: CGFloat {
        let imageAdjustment = CGFloat(5)
        return ((font.lineHeight - font.capHeight) / 2) - imageAdjustment
    }

    var body: some View {
        GeometryReader { geometry in
            let baseText = HStack(alignment: .center, spacing: 8) {
                ForEach(0..<words.count, id: \.self) { idx in
                    Text(words[idx])
                        .font(Font(font))
                        .offset(x: 0, y: textVerticalOffset)
                    separator
                        .padding(.horizontal, separatorPadding)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 0) {
                    ForEach(0..<50000) { _ in
                        baseText
                            .padding(.horizontal, 4)
                    }
                }
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.onAppear {
                            contentWidth = contentGeometry.size.width / 4 // Divide by number of copies
                            screenWidth = geometry.size.width
                            // Start from left side for trailing direction
                            offset = direction == .trailing ? -contentWidth : 0
                        }
                    }
                )
                .offset(x: offset)
                .onAppear {
                    startScrolling()
                }
            }
            .disabled(true)
            .allowsHitTesting(false)
        }
    }

    private func startScrolling() {
        let speed: CGFloat = 0.1

        Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { timer in
            switch direction {
            case .leading:
                offset -= speed
                if -offset >= contentWidth {
                    offset = 0
                }
            case .trailing:
                offset += speed
                if offset >= contentWidth {
                    offset = 0
                }
            }
        }
    }
}

#Preview("Marquee Trailing") {
    MarqueeTextView(words: ["Pocket", "Casts", "2024"].map({$0.uppercased()}), separator: Image("playback-24-heart"), direction: .trailing)
}
