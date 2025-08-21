import SwiftUI
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self.first?.hashValue) { rowElements in
                HStack(spacing: spacing) {
                    Spacer()
                    ForEach(rowElements, id: \.self.hashValue) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }

    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]

            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow = currentRow + 1
                rows.append([element])
                remainingWidth = availableWidth
            }

            remainingWidth = remainingWidth - (elementSize.width + spacing)
        }

        return rows
    }
}

// MARK: - EXTENSION

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

#Preview("Live") {
    GeometryReader { geometryProxy in
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)
                FlexibleView(
                    availableWidth: geometryProxy.size.width,
                    data: ["Arts", "True Crime", "Fiction", "News", "Bussines", "Technology", "Sports"],
                    spacing: 8,
                    alignment: .center
                ) { text in
                    Text(text).font(.title)
                }
            }
        }
    }
    .environmentObject(Theme(previewTheme: .light))
}
