import Kingfisher
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

struct PodcastPickerRow: View {
    @EnvironmentObject var theme: Theme

    @Binding var pickingForFolderUuid: String?
    @State var podcast: Podcast
    @Binding var selectedPodcasts: [String]
    var body: some View {
        HStack {
            KFImage(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
                .resizable()
                .frame(width: 56, height: 56)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(4)
                .shadow(radius: 2, x: 0, y: 1)
                .accessibilityHidden(true) // without this set, iOS will attempt to describe the image which is amazing, but not needed in this case
            VStack(alignment: .leading, spacing: 2) {
                if let folderUuid = podcast.folderUuid, pickingForFolderUuid != folderUuid, let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
                    HStack {
                        Image("folder-small")
                            .foregroundColor(AppTheme.folderColor(colorInt: folder.color).color)
                        Text(folder.name)
                            .strikethrough(selectedPodcasts.contains(podcast.uuid))
                            .font(.footnote)
                            .foregroundColor(AppTheme.folderColor(colorInt: folder.color).color)
                        Spacer()
                    }
                }
                Text(podcast.title ?? "")
                    .textStyle(PrimaryText())
                    .font(.callout)
                    .lineLimit(2)
                Text(podcast.author ?? "")
                    .textStyle(SecondaryText())
                    .font(.footnote)
                    .lineLimit(1)
            }
            .padding(.leading, 2)
            Spacer()
            ZStack {
                if selectedPodcasts.contains(podcast.uuid) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
                        .frame(width: 24, height: 24)
                    Image("small-tick")
                        .foregroundColor(ThemeColor.primaryInteractive02(for: theme.activeTheme).color)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ThemeColor.primaryInteractive01(for: theme.activeTheme).color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PodcastPickerRow_TickedPreview: PreviewProvider {
    static var previews: some View {
        PodcastPickerRow(pickingForFolderUuid: .constant(nil), podcast: Podcast.previewPodcast(), selectedPodcasts: .constant([Podcast.previewPodcast().uuid]))
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Selected")
    }
}

struct PodcastPickerRow_UnTickedPreview: PreviewProvider {
    static var previews: some View {
        PodcastPickerRow(pickingForFolderUuid: .constant(nil), podcast: Podcast.previewPodcast(), selectedPodcasts: .constant([]))
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Not Selected")
    }
}
