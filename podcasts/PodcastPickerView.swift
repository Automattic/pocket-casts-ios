import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

struct PodcastPickerView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var pickerModel: PodcastPickerModel

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                HStack {
                    PCSearchView(searchTerm: $pickerModel.searchTerm)
                        .frame(height: PCSearchView.defaultHeight)
                        .padding(.top, 11)
                        .padding(.leading, -PCSearchView.defaultIndenting)
                    Spacer()
                    Menu {
                        SortByView(sortType: .titleAtoZ, pickerModel: pickerModel)
                        SortByView(sortType: .episodeDateNewestToOldest, pickerModel: pickerModel)
                        SortByView(sortType: .dateAddedNewestToOldest, pickerModel: pickerModel)
                    } label: {
                        Image("podcast-sort")
                            .accessibilityLabel(L10n.podcastsSort)
                            .foregroundColor(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ThemeColor.primaryInteractive01(for: theme.activeTheme).color, lineWidth: 2)
                            )
                    }
                }
                .padding(.top, 3)
                ThemedDivider()
                Text(L10n.selectedPodcastCount(pickerModel.selectedPodcastUuids.count, capitalized: true))
                    .font(.subheadline)
                    .textStyle(PrimaryText())
                    .padding(.top, 3)
                ThemedDivider()
            }
            .padding(.horizontal)

            List(pickerModel.filteredPodcasts) { podcast in
                Button {
                    pickerModel.togglePodcastSelected(podcast)
                } label: {
                    PodcastPickerRow(pickingForFolderUuid: $pickerModel.pickingForFolderUuid, podcast: podcast, selectedPodcasts: $pickerModel.selectedPodcastUuids)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 4))
                .listRowBackground(ThemeColor.primaryUi01(for: theme.activeTheme).color)
                .hideListRowSeperators()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary(podcast: podcast, selectedPodcasts: pickerModel.selectedPodcastUuids))
                .accessibility(addTraits: .isButton)
            }
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height < 0 {
                        // hide keyboard on scroll down
                        UIApplication.shared.endEditing()
                    }
                }
            )
            .listStyle(PlainListStyle())
        }
    }

    private func accessibilitySummary(podcast: Podcast, selectedPodcasts: [String]) -> String {
        var str = podcast.title ?? ""

        if selectedPodcasts.contains(podcast.uuid) {
            str += " \(L10n.statusSelected)"
        } else {
            str += " \(L10n.statusNotSelected)"
        }

        return str
    }
}

struct SortByView: View {
    @State var sortType: LibrarySort
    @ObservedObject var pickerModel: PodcastPickerModel

    var body: some View {
        Button {
            pickerModel.sortType = sortType
            Analytics.track(.folderPodcastPickerFilterChanged, properties: ["sort_order": sortType])
        } label: {
            HStack {
                Text(sortType.description)
                Spacer()
                if pickerModel.sortType == sortType {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct PodcastPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastPickerView(pickerModel: PodcastPickerModel())
            .environmentObject(Theme(previewTheme: .light))
    }
}
