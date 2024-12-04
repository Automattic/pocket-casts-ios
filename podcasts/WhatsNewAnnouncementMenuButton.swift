import SwiftUI

struct WhatsNewAnnouncementMenuButton: View {
    @State var showPickerAlert: Bool = false
    @State var selectedYear: EndOfYear.Year = EndOfYear.Year.y2024
    @State var lastWhatsNewShown: String = Settings.lastWhatsNewShown ?? Settings.appVersion()

    var body: some View {
        Button("Reset last announcement showed") {
            showPickerAlert = true
        }
        .sheet(isPresented: $showPickerAlert) {
            let options = WhatsNew().announcements
            VStack {
                Spacer()
                Picker("Select a version", selection: $lastWhatsNewShown) {
                    ForEach(options, id: \.version) { option in
                        Text("Announcement for \(option.version)")
                    }
                }
                .pickerStyle(.wheel)
                VStack {
                    Button("Select") {
                        Settings.lastWhatsNewShown = lastWhatsNewShown
                        showPickerAlert = false
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(RoundedButtonStyle(theme: .sharedTheme))
                    Button("Cancel") {
                        showPickerAlert = false
                    }
                    .buttonStyle(RoundedButtonStyle(theme: .sharedTheme))
                }
                .padding()
            }
            .modify {
                if #available(iOS 16, *) {
                    $0.presentationDetents([.medium])
                }
            }
        }
    }
}

#Preview {
    WhatsNewAnnouncementMenuButton()
}
