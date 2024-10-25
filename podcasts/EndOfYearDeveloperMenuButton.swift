import SwiftUI

struct EndOfYearDeveloperMenuButton: View {
    @State var showPickerAlert: Bool = false
    @State var selectedYear: EndOfYear.Year = EndOfYear.Year.y2024

    var body: some View {
        Button("Reset modal/profile badge") {
            showPickerAlert = true
        }
        .sheet(isPresented: $showPickerAlert) {
            let options = EndOfYear.Year.allCases.filter({ $0.year != nil })
            VStack {
                Spacer()
                Picker("Select a year", selection: $selectedYear) {
                    ForEach(options, id: \.self) { option in
                        Text( String(option.year ?? 0))
                    }
                }
                .pickerStyle(.wheel)
                VStack {
                    Button("Reset") {
                        if let year = selectedYear.year {
                            Settings.setHasShownModalForEndOfYear(false, year: year)
                            Settings.setShowBadgeForEndOfYear(true, year: year)
                        }
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
