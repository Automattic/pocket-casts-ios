import SwiftUI
import PocketCastsDataModel

struct OrderPickerView<T>: View where T: SortOption {
    @Environment(\.presentationMode) var presentationMode
    let selectedOption: T
    let didSelectOption: (T) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                Text(T.pickerTitle)
                    .font(.dynamic(size: 16))
                    .padding(.top, 5)
                ForEach(Array(T.allCases)) { option in
                    Text(option.description)
                        .font(.dynamic(size: 16))
                        .opacity(option == selectedOption ? 0.2 : 1)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.background)
                        .cornerRadius(WatchConstants.cornerRadius)
                        .onTapGesture {
                            self.didSelectOption(option)
                        }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(L10n.cancel)
                }
            }
        }
    }
}

struct OrderPicker_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices, id: \.rawValue) { device in
            OrderPickerView(selectedOption: PodcastEpisodeSortOrder.newestToOldest) { _ in
            }
            .previewDevice(device)
        }
    }
}
