import SwiftUI
import PocketCastsUtils

private struct RowMockup: View {
    let title: String
    let episodeTitle: String
    let date: String
    let timestamp: String
    let hasTranscript: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.8))
                .frame(width: 56, height: 56)
                .overlay(Text("A").font(.title2.bold()).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 4) {
                Text(episodeTitle)
                    .foregroundStyle(.secondary)
                    .font(style: .caption, weight: .semibold)
                    .lineLimit(1)

                Text(title)
                    .foregroundStyle(.primary)
                    .font(style: .subheadline, weight: .medium)
                    .lineLimit(1)

                Text("\(date) · \(timestamp)")
                    .foregroundStyle(.secondary)
                    .font(style: .caption, weight: .semibold)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if hasTranscript {
                Image(systemName: "text.quote")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

#Preview("Timestamp in subtitle + icon buttons") {
    VStack(spacing: 0) {
        RowMockup(title: "Higher Education Myths", episodeTitle: "Higher Education's Identity Crisis", date: "Jun 4 · 11:41 PM", timestamp: "07:23", hasTranscript: true)
        Divider().padding(.leading, 86)
        RowMockup(title: "Cuba News", episodeTitle: "Is Cuba Next?", date: "Jun 4 · 11:38 PM", timestamp: "08:19", hasTranscript: true)
        Divider().padding(.leading, 86)
        RowMockup(title: "FBI News", episodeTitle: "Kash Patel's FBI", date: "Jun 4 · 11:34 PM", timestamp: "18:27", hasTranscript: true)
        Divider().padding(.leading, 86)
        RowMockup(title: "Natalie Heller Mills, yesteryear was...", episodeTitle: "The Tragedy of the Trainwife", date: "Jun 4 · 11:33 PM", timestamp: "04:11", hasTranscript: true)
        Divider().padding(.leading, 86)
        RowMockup(title: "AI Questions", episodeTitle: "Is 'Opinions' Your Happiness? This...", date: "Jun 4 · 11:23 PM", timestamp: "21:45", hasTranscript: false)
    }
}
