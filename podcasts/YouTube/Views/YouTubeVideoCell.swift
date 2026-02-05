import SwiftUI

/// A cell displaying a YouTube video
struct YouTubeVideoCell: View {
    let video: YouTubeVideo
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                thumbnailView

                // Video info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let author = video.author {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        if let publishedDate = video.publishedDate {
                            Text(formatDate(publishedDate))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let viewCount = video.viewCount {
                            Text(formatViewCount(viewCount))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let duration = video.duration {
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var thumbnailView: some View {
        AsyncImage(url: thumbnailURL) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.gray)
                    )
            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 120, height: 68)
        .cornerRadius(8)
        .clipped()
    }

    private var thumbnailURL: URL? {
        if let urlString = video.thumbnailURL {
            return URL(string: urlString)
        }
        // Default YouTube thumbnail
        return URL(string: "https://i.ytimg.com/vi/\(video.id)/mqdefault.jpg")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatViewCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM views", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK views", Double(count) / 1_000)
        }
        return "\(count) views"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    List {
        YouTubeVideoCell(video: YouTubeVideo.preview()) {
            print("Tapped!")
        }
        .listRowInsets(EdgeInsets())

        ForEach(YouTubeVideo.previewList()) { video in
            YouTubeVideoCell(video: video) {
                print("Tapped \(video.title)")
            }
            .listRowInsets(EdgeInsets())
        }
    }
    .listStyle(.plain)
}
