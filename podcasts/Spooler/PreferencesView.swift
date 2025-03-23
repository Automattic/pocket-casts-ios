import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

enum PreferenceSection: Int, CaseIterable {
    case location
    case birthday
    case news
    case sports
    case stocks
    case emailNewsletters

    var title: String {
        switch self {
        case .location: return "Location"
        case .birthday: return "Birthday"
        case .news: return "News Sources"
        case .sports: return "Sports"
        case .stocks: return "Stocks"
        case .emailNewsletters: return "Email Newsletters"
        }
    }

    var options: [String] {
        switch self {
        case .location: return ["Current Location", "Belmont", "San Francisco", "New York", "London", "Berlin"]
        case .birthday: return []
        case .news: return ["Washington Post", "New York Times", "Financial Times", "Der Welt", "TMZ"]
        case .sports: return ["General", "Headlines"]
        case .stocks: return ["DAX", "FTSE", "INDI", "DJI", "INX", "VOW", "VWAGY", "AAPL", "GOOG", "MSFT"]
        case .emailNewsletters: return ["Semafor Flagship", "Garbage Day", "Sounds Profitable", "Morning Brew", "Dirt"]
        }
    }
}

struct Preferences {
    var selectedOptions: [PreferenceSection: Set<String>]
    var birthday: Date?
}

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: Preferences
    @State private var selectedDate = Date(timeIntervalSince1970: 233395200) // May 25, 1977
    var onUpdate: (Preferences) -> Void

    init(preferences: Preferences = Preferences(selectedOptions: [:], birthday: nil), onUpdate: @escaping (Preferences) -> Void) {
        _preferences = State(initialValue: preferences)
        self.onUpdate = onUpdate
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(PreferenceSection.birthday.title)) {
                    DatePicker(
                        "Birthday",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                ForEach(PreferenceSection.allCases.filter { $0 != .birthday }, id: \.self) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.options, id: \.self) { option in
                            Button(action: {
                                toggleOption(section: section, option: option)
                            }) {
                                HStack {
                                    Text(option)
                                    Spacer()
                                    if preferences.selectedOptions[section]?.contains(option) ?? false {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(ThemeColor.primaryInteractive01()))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        preferences.birthday = selectedDate
                        onUpdate(preferences)
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleOption(section: PreferenceSection, option: String) {
        if preferences.selectedOptions[section]?.contains(option) ?? false {
            preferences.selectedOptions[section]?.remove(option)
        } else {
            if preferences.selectedOptions[section] == nil {
                preferences.selectedOptions[section] = Set<String>()
            }
            preferences.selectedOptions[section]?.insert(option)
        }
    }
}

#Preview {
    PreferencesView(
        preferences: Preferences(
            selectedOptions: [
                .location: ["San Francisco"],
                .news: ["General"],
                .sports: ["General"],
                .stocks: ["AAPL", "GOOG"],
                .emailNewsletters: ["Morning Brew"]
            ],
            birthday: nil
        )
    ) { _ in }
}
