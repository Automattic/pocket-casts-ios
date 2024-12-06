import SwiftUI

struct WhatsNewAnnouncementMenuList: View {
    private let announcements = WhatsNew().announcements
    @State private var selectedAnnouncement: WhatsNew.Announcement?
    @State private var showingSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    Button("Reset Last Shown") {
                        guard
                            let splitVersion = announcements.last?.version.split(separator: "."),
                            let major = splitVersion[safe: 0],
                            let minorString = splitVersion[safe: 1],
                            let minor = Int(minorString)
                        else {
                            return
                        }
                        Settings.lastWhatsNewShown =  "\(major).\(minor-1)"
                    }
                    .frame(height: 44)

                    ForEach(announcements, id: \.id) { announcement in
                        WhatsNewAnnouncementRow(announcement: announcement)
                            .frame(minHeight: 64)
                            .onTapGesture {
                                selectedAnnouncement = announcement
                            }
                    }
                }
            }
            .modifier(MiniPlayerPadding())
            .sheet(item: $selectedAnnouncement) {
                WhatsNewView(announcement: $0, debug: true)
                    .setupDefaultEnvironment()
            }
        }
    }

    struct WhatsNewAnnouncementRow: View {
        let announcement: WhatsNew.Announcement

        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(announcement.version)
                        .font(.headline)
                    Spacer()
                }
                if !announcement.title.isEmpty {
                    HStack {
                        Text(announcement.title)
                            .font(.body)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(.white)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    WhatsNewAnnouncementMenuList()
}
