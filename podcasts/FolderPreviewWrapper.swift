import PocketCastsDataModel
import SwiftUI

struct FolderPreviewWrapper: UIViewRepresentable {
    @ObservedObject var model: FolderModel
    @State var showName = false

    func makeUIView(context: Context) -> FolderPreviewView {
        FolderPreviewView()
    }

    func updateUIView(_ folderView: FolderPreviewView, context: Context) {
        folderView.showFolderName = showName

        if let folderUuid = model.folderUuid, let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
            folderView.populateFrom(folder: folder)
        } else {
            folderView.populateFrom(model: model)
        }
    }
}
