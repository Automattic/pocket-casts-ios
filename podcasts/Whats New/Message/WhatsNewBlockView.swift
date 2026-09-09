import PocketCastsServer
import SwiftUI

/// One block of a What's New page, drawn the way its type calls for.
struct WhatsNewBlockView: View {
    let block: WhatsNewBlock

    /// The space the page has for its content, which media sizes itself against.
    let contentSize: CGSize

    /// Whether the page this block is on is the one on screen, so a video only plays in view.
    let isVisible: Bool

    var body: some View {
        switch block {
        case .heading(let heading):
            WhatsNewHeadingView(heading: heading)
        case .paragraph(let paragraph):
            WhatsNewParagraphView(paragraph: paragraph)
        case .image(let image):
            WhatsNewImageView(image: image, contentSize: contentSize)
        case .video(let video):
            WhatsNewVideoView(video: video, contentSize: contentSize, isVisible: isVisible)
        case .action(let action):
            WhatsNewActionView(action: action)
        }
    }
}

/// How big a What's New image or video draws on a page.
enum WhatsNewMediaLayout {
    /// The share of a page the design gives its screenshot, which leaves room for the text beneath.
    private static let heightFraction: CGFloat = 0.52

    /// As wide as the page allows, but never so tall that it pushes what follows it off the page.
    static func size(aspectRatio: CGFloat, in contentSize: CGSize) -> CGSize {
        let height = min(contentSize.height * heightFraction, contentSize.width / aspectRatio)
        return CGSize(width: height * aspectRatio, height: height)
    }
}

// MARK: - Text

private struct WhatsNewHeadingView: View {
    @EnvironmentObject private var theme: Theme

    let heading: WhatsNewHeading

    var body: some View {
        Text(heading.text)
            .font(size: fontSize, style: textStyle, weight: .semibold)
            .foregroundStyle(theme.primaryText01)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var fontSize: Double {
        heading.level <= 1 ? 22 : 17
    }

    private var textStyle: Font.TextStyle {
        heading.level <= 1 ? .title3 : .headline
    }
}

private struct WhatsNewParagraphView: View {
    @EnvironmentObject private var theme: Theme

    let paragraph: WhatsNewParagraph

    var body: some View {
        Text(paragraph.content)
            .font(size: 15, style: .subheadline)
            .foregroundStyle(theme.primaryText01)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Image

/// An image block, sized from the dimensions the catalog published so the page doesn't reflow
/// around it once it loads.
private struct WhatsNewImageView: View {
    let image: WhatsNewImage
    let contentSize: CGSize

    var body: some View {
        Group {
            if let aspectRatio {
                let size = WhatsNewMediaLayout.size(aspectRatio: aspectRatio, in: contentSize)

                imageView(aspectRatio: aspectRatio)
                    .frame(width: size.width, height: size.height)
            } else {
                imageView(aspectRatio: nil)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(image.alt == nil)
        .accessibilityLabel(image.alt ?? "")
        .accessibilityAddTraits(.isImage)
    }

    private func imageView(aspectRatio: CGFloat?) -> some View {
        AsyncImageView(url: image.url,
                       cache: ImageManager.sharedManager.discoverCache,
                       aspectRatio: aspectRatio,
                       contentMode: .fit)
    }

    /// The shape the catalog published, or `nil` when it published no dimensions and the image has
    /// to size itself once it arrives.
    private var aspectRatio: CGFloat? {
        guard let width = image.width, let height = image.height, width > 0, height > 0 else { return nil }
        return CGFloat(width) / CGFloat(height)
    }
}

// MARK: - Action

/// A call to action, which opens an in-app destination or a web page.
///
/// A URL the app has no way to open isn't drawn at all: whether the action succeeds or fails has
/// nothing to do with the message being read, so there's nothing to report back either way.
struct WhatsNewActionView: View {
    @EnvironmentObject private var theme: Theme

    let action: WhatsNewAction

    var body: some View {
        if let link = WhatsNewLink(url: action.url) {
            switch action.style {
            case .primary:
                button(opening: link)
                    .buttonStyle(RoundedButtonStyle(theme: theme))
            case .secondary:
                button(opening: link)
                    .buttonStyle(StrokeButton(textColor: theme.primaryInteractive01,
                                              backgroundColor: .clear,
                                              strokeColor: theme.primaryInteractive01))
            }
        }
    }

    private func button(opening link: WhatsNewLink) -> some View {
        Button(action.label) {
            link.open()
        }
    }
}
