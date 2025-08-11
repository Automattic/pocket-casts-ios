import UIKit
import SwiftUI

fileprivate struct SmartPlaylistCreationView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        Button {

        }  label: {
            HStack {
                icon(for: theme.activeTheme)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(theme.primaryIcon01)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Spacer()
                Image("cs-chevron")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryIcon01)
                    .frame(width: 24, height: 24)
            }
            .frame(minHeight: 59.0)
        }
        .background(theme.secondaryText01)
    }

    private func icon(for themeType: Theme.ThemeType) -> Image {
        let name: String
        switch themeType {
        case .classic, .rosé:
            name = "cs-sparkle-red"
        case .indigo:
            name = "cs-sparkle-indigo"
        case .radioactive:
            name = "cs-sparkle-green"
        case .contrastLight:
            name = "cs-sparkle-black"
        case .contrastDark:
            name = "cs-sparkle-gray"
        default:
            name = "cs-sparkle-blue"
        }
        return Image(name)
    }
}

class NewPlaylistViewController: PCViewController {
    weak var delegate: FilterCreatedDelegate?

    private var playlistName: String = ""
    private var playlistNameTextField: ThemeableTextField! {
        didSet {
            playlistNameTextField.translatesAutoresizingMaskIntoConstraints = false
            playlistNameTextField.placeholder = L10n.playlistsEmptyStateButton
            playlistNameTextField.delegate = self
            playlistNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
            playlistNameTextField.clearButtonMode = .whileEditing
            playlistNameTextField.font = .systemFont(ofSize: 15, weight: .regular)
            playlistNameTextField.tintColor = AppTheme.colorForStyle(.primaryField03)
        }
    }

    private var textFieldBorderView: UIView! {
        didSet {
            textFieldBorderView.translatesAutoresizingMaskIntoConstraints = false
            textFieldBorderView.layer.borderWidth = 2
            textFieldBorderView.layer.cornerRadius = 6
            textFieldBorderView.layer.borderColor = AppTheme.colorForStyle(.primaryField03).cgColor
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        addCloseButton()
        setupContent()
    }

    private func setupNavBar() {
        title = L10n.playlistsEmptyStateButton

        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)

        navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.sizeToFit()
    }

    private func setupContent() {
        view.backgroundColor = AppTheme.viewBackgroundColor()

        textFieldBorderView = ThemeableSelectionView()
        view.addSubview(textFieldBorderView)

        playlistNameTextField = ThemeableTextField()
        view.addSubview(playlistNameTextField)

        let a = SmartPlaylistCreationView().themedUIView
        a.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(a)

        NSLayoutConstraint.activate([
            textFieldBorderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10.0),
            textFieldBorderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            textFieldBorderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            textFieldBorderView.heightAnchor.constraint(equalToConstant: 56.0),

            playlistNameTextField.topAnchor.constraint(equalTo: textFieldBorderView.topAnchor),
            playlistNameTextField.leadingAnchor.constraint(equalTo: textFieldBorderView.leadingAnchor, constant: 16.0),
            playlistNameTextField.trailingAnchor.constraint(equalTo: textFieldBorderView.trailingAnchor, constant: -16.0),
            playlistNameTextField.bottomAnchor.constraint(equalTo: textFieldBorderView.bottomAnchor),

            a.topAnchor.constraint(equalTo: textFieldBorderView.bottomAnchor, constant: 16.0),
            a.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            a.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            a.heightAnchor.constraint(equalToConstant: 59.0),
        ])

        view.layoutSubviews()
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    private func createManualPlaylist() {

    }

    private func createSmartPlaylist() {

    }

    @objc private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func textFieldDidChange() {
        playlistName = playlistNameTextField.text ?? ""
    }
}

extension NewPlaylistViewController: UITextFieldDelegate {
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        return true
//    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        playlistName = ""
        return true
    }
}
