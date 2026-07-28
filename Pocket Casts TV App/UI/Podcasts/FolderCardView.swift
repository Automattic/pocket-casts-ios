import SwiftUI
import PocketCastsDataModel

struct FolderCardView: View {

    var folder: Folder
    @State var model: FolderCardViewModel

    init(folder: Folder) {
        self.folder = folder
        self.model = FolderCardViewModel(folder: folder)
    }

    private let cardSize: CGFloat = 250
    private let coverSize: CGFloat = 80
    private let coverSpacing: CGFloat = 6

    private let gradient = LinearGradient(
        colors: [Color(red: 0x60/255, green: 0x46/255, blue: 0xE9/255),
                 Color(red: 0xE7/255, green: 0x4B/255, blue: 0x8A/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            coverGrid
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 24)
            folderName
                .padding(.bottom, 16)
        }
        .frame(width: cardSize, height: cardSize)
        .background(Color(uiColor: AppTheme.folderColor(colorInt: model.folder.color)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusedCardDepth(cornerRadius: 12, style: .surface)
        .task {
            model.load()
        }
        .onChange(of: folder) {
            model.folder = folder
            model.load()
        }
    }

    private var coverGrid: some View {
        Grid(horizontalSpacing: coverSpacing, verticalSpacing: coverSpacing) {
            GridRow {
                coverImage(at: 0)
                coverImage(at: 1)
            }
            GridRow {
                coverImage(at: 2)
                coverImage(at: 3)
            }
        }
    }

    @ViewBuilder
    private func coverImage(at index: Int) -> some View {
        if index < model.topPodcastsUuids.count {
            PodcastImage(uuid: model.topPodcastsUuids[index], size: .list)
                .frame(width: coverSize, height: coverSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Color.black.opacity(0.2)
                .frame(width: coverSize, height: coverSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var folderName: some View {
        MarqueeText(text: model.folder.name, maxWidth: cardSize - 32)
    }
}

private struct MarqueeText: View {
    let text: String
    let maxWidth: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    private var overflows: Bool { textWidth > maxWidth }

    var body: some View {
        let label = Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .fixedSize()

        Group {
            if overflows {
                label
                    .offset(x: offset)
                    .onAppear { startScrolling() }
                    .onDisappear { offset = 0 }
            } else {
                label
            }
        }
        .frame(width: maxWidth, alignment: overflows ? .leading : .center)
        .clipped()
        .background(
            label
                .hidden()
                .overlay(GeometryReader { geo in
                    Color.clear.onAppear { textWidth = geo.size.width }
                })
        )
    }

    private func startScrolling() {
        let travel = textWidth - maxWidth
        withAnimation(
            .linear(duration: Double(travel) / 30)
            .delay(1)
            .repeatForever(autoreverses: true)
        ) {
            offset = -travel
        }
    }
}

#Preview {
    let folders = MockData.makeStubFolders()
    LazyVGrid(columns: [GridItem(.fixed(250), spacing: 48), GridItem(.fixed(250), spacing: 48)], spacing: 48) {
        ForEach(folders) { folder in
            FolderCardView(folder: folder)
        }
    }
    .padding()
    .background(Color.black)
}
