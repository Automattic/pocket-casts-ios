import SwiftUI

struct ColorSelectRow: View {
    @ObservedObject var model: FolderModel

    let availableColors = [0, 6, 2, 1, 3, 9, 7, 4, 10, 8, 5, 11] // maintain color order to match with Android and Web client.
    let spacing: CGFloat = 12
    let circleWidth: CGFloat = 40

    var body: some View {
        // using GeometryReader because LazyVGrid requires a fixed column count and doesn't support automatic wrapping. New iOS 16 grids might help here once we can require newer iOS versions.
        GeometryReader { geometry in
            LazyVGrid(columns: getColumns(gridWidth: geometry.size.width), alignment: .leading, spacing: spacing) {
                ForEach(availableColors, id: \.self) { colorId in
                    ColorSelectCircle(folderColorId: colorId, model: model)
                }
            }
        }
        .frame(height: circleWidth * 2 + spacing) // forced height hack to stop GeometryReader from taking all available vertical space. Since we'll always have 2 rows it should be fine. Update this if we ever add more colors that force a 3rd row.
    }

    func getColumns(gridWidth: CGFloat) -> [GridItem] {
        var columns = [GridItem]()
        let sizing = circleWidth + spacing
        for _ in 0 ... Int(gridWidth / sizing) {
            columns.append(GridItem(.fixed(circleWidth)))
        }
        return columns
    }
}
