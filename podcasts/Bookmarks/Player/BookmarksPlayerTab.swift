import SwiftUI

struct BookmarksPlayerTab: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        ZStack {
            Color.blue

            Text("Hello!")
                .foregroundStyle(Color.white)
        }
    }
}

class BookmarksPlayerTabController: PlayerItemViewController {
    private let controller = ThemedHostingController(rootView: BookmarksPlayerTab())

    override func loadView() {
        self.view = controller.view.map {
            let view = UIStackView(arrangedSubviews: [$0])
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            return view
        } ?? UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(controller)
    }
}

struct BookmarksPlayerTab_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksPlayerTab()
            .setupDefaultEnvironment()
    }
}
