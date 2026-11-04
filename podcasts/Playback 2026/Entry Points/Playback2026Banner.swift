import SwiftUI

/// The permanent Playback 2026 entry point at the top of the Profile tab.
struct Playback2026Banner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.playback2026BannerTitle)
                .font(size: 18, style: .title3, weight: .bold, maxSizeCategory: .extraExtraLarge)
                .tracking(-0.36)
            Text(L10n.playback2026BannerDescription)
                .font(size: 11, style: .caption, weight: .medium, maxSizeCategory: .accessibilityMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background {
            Image("playback-2026-banner")
                .resizable()
                .scaledToFill()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

final class Playback2026BannerCell: ThemeableCell {
    static let identifier = "Playback2026BannerCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let bannerView = Playback2026Banner().themedUIView
        bannerView.backgroundColor = .clear
        contentView.addSubview(bannerView)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11)
        ])

        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    Playback2026Banner()
        .padding(16)
}
