import UIKit

class ThemeableCollectionCell: UICollectionViewCell {
    var style: ThemeStyle = .primaryUi02 {
        didSet {
            updateColor(AppTheme.colorForStyle(style))
        }
    }

    private var reorderHandle: CellReorderHandleView?

    var showsReorderHandle: Bool {
        get { reorderHandle?.isVisible ?? false }
        set {
            guard newValue else {
                reorderHandle?.isVisible = false
                return
            }
            if reorderHandle == nil {
                let handle = CellReorderHandleView(maskedView: contentView)
                addSubview(handle)
                NSLayoutConstraint.activate([
                    handle.leadingAnchor.constraint(equalTo: leadingAnchor),
                    handle.trailingAnchor.constraint(equalTo: trailingAnchor),
                    handle.topAnchor.constraint(equalTo: topAnchor),
                    handle.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
                reorderHandle = handle
            }
            reorderHandle?.isVisible = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        updateColor(AppTheme.colorForStyle(style))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        updateColor(AppTheme.colorForStyle(style))
        handleThemeDidChange()
    }

    func handleThemeDidChange() {}

    private func updateColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
    }
}
