import SwiftUI

struct HorizontalCarouselCard: View {
    let item: any HorizontalCarouselItemRepresentable

    private var isiPad: Bool {
        UIDevice.current.isiPad()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(item.backgroundColor)
            VStack(alignment: isiPad ? .center : .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Image(item.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 243.0, minHeight: 152.0, maxHeight: 217.0)
                    Spacer()
                }
                .padding(.top, isiPad ? 20.0 : 40.0)
                .padding(.bottom, isiPad ? 16.0 : 24.0)
                Spacer()
                text(item.title,
                     size: item.titleSize,
                     weight: .semibold,
                     lineLimit: 2,
                     color: item.titleColor)
                .padding(.horizontal, isiPad ? 65 : 24.0)
                text(item.text,
                     size: item.textSize,
                     weight: .regular,
                     lineLimit: 3,
                     color: item.textColor)
                .padding(.horizontal, isiPad ? 76 : 24.0)
                .padding(.top, 4.0)
                .padding(.bottom, isiPad ? 20.0 : 24.0)
            }
        }
    }

    @ViewBuilder
    private func text(_ text: String, size: Double, weight: Font.Weight, lineLimit: Int, color: Color = .white) -> some View {
        Text(text)
            .font(size: size, style: .body, weight: weight)
            .foregroundStyle(color)
            .multilineTextAlignment(isiPad ? .center : .leading)
            .lineLimit(lineLimit)
    }
}

fileprivate enum MockItem: String, CaseIterable, Identifiable, HorizontalCarouselItemRepresentable {
    case test

    var backgroundColor: Color {
        .red
    }

    var titleColor: Color {
        .black
    }

    var titleSize: CGFloat {
        18.0
    }

    var textColor: Color {
        .gray
    }

    var textSize: CGFloat {
        14.0
    }

    var title: String {
        "Lorem Ipsum dolor sit amet"
    }

    var text: String {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    }

    var image: String {
        "informational_card_sync"
    }
}

#Preview {
    HorizontalCarouselCard(item: MockItem.test)
        .frame(width: 313, height: 370)
}
