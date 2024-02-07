
import UIKit

class WhatsNewPageView: ThemeableView {
    var whatsNewLinkDelegate: WhatsNewLinkDelegate?
    @IBOutlet var contentView: ThemeableView!

    @IBOutlet var topPaddingView: ThemeableView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var scrollView: UIScrollView! {
        didSet {
            scrollView.isDirectionalLockEnabled = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.isPagingEnabled = false
        }
    }

    private var pageInfo: WhatsNewPage

    required init(pageInfo: WhatsNewPage, whatsNewLinkDelegate: WhatsNewLinkDelegate?) {
        self.pageInfo = pageInfo
        self.whatsNewLinkDelegate = whatsNewLinkDelegate
        super.init(frame: CGRect.zero)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("WhatsNewPageView init(coder) not implemented")
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("WhatsNewPageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.anchorToAllSidesOf(view: self)

        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.distribution = .fill

        var constraintsToActivate = [NSLayoutConstraint]()

        for item in pageInfo.items {
            if item.type == "image" {
                if let resourceName = item.resource {
                    let horizontalStack = UIStackView()
                    horizontalStack.axis = .horizontal
                    horizontalStack.distribution = .fillEqually

                    let imageView = WhatsNewThemeableImageView(imageName: resourceName)
                    imageView.contentMode = .bottomLeft
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    horizontalStack.addArrangedSubview(imageView)
                    constraintsToActivate.append(horizontalStack.widthAnchor.constraint(equalTo: stackView.widthAnchor))

                    if let secondaryIcon = pageInfo.items.filter({ $0.type == "secondary_image" }).first, let secondaryResource = secondaryIcon.resource {
                        let imageView = WhatsNewThemeableImageView(imageName: secondaryResource)
                        imageView.contentMode = .bottomRight
                        imageView.translatesAutoresizingMaskIntoConstraints = false
                        horizontalStack.addArrangedSubview(imageView)
                    }

                    stackView.addArrangedSubview(horizontalStack)
                }
            } else if item.type == "title" {
                if let text = item.text {
                    let titleLabel = ThemeableLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 37))
                    titleLabel.text = Bundle.main.localizedString(forKey: text, value: text, table: nil)
                    titleLabel.font = UIFont.systemFont(ofSize: 31, weight: .bold)
                    titleLabel.numberOfLines = 0
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addArrangedSubview(titleLabel)
                    constraintsToActivate.append(titleLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
                    constraintsToActivate.append(titleLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
                }
            } else if item.type == "body" {
                if let text = item.text {
                    let bodyLabel = ThemeableLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    bodyLabel.text = Bundle.main.localizedString(forKey: text, value: text, table: nil)
                    bodyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                    bodyLabel.numberOfLines = 0
                    bodyLabel.setLineSpacing(lineSpacing: 1, lineHeightMultiple: 1.1)
                    bodyLabel.style = .primaryText02
                    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addArrangedSubview(bodyLabel)
                    constraintsToActivate.append(bodyLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
                    constraintsToActivate.append(bodyLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
                }
            } else if item.type == "link" {
                if let text = item.text, let urlString = item.url, let url = URL(string: urlString) {
                    let button = WhatsNewLinkButton(url: url)
                    button.setTitle(Bundle.main.localizedString(forKey: text, value: text, table: nil), for: .normal)
                    button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 18)
                    button.titleLabel?.textAlignment = .natural
                    button.buttonStyle = .primaryUi01
                    button.textStyle = .primaryInteractive01
                    button.contentMode = .center
                    button.contentHorizontalAlignment = .leading
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    button.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addArrangedSubview(button)
                    constraintsToActivate.append(button.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
                    constraintsToActivate.append(button.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
                }
            } else if item.type == "in_app_link" {
                if let text = item.text, let urlString = item.url, let url = URL(string: urlString) {
                    let button = WhatsNewLinkButton(navigationKey: url.absoluteString)
                    button.delegate = whatsNewLinkDelegate
                    button.setTitle(Bundle.main.localizedString(forKey: text, value: text, table: nil), for: .normal)
                    button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 18)
                    button.titleLabel?.textAlignment = .natural
                    button.buttonStyle = .primaryUi01
                    button.textStyle = .primaryInteractive01
                    button.contentHorizontalAlignment = .leading
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    button.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addArrangedSubview(button)
                    constraintsToActivate.append(button.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
                    constraintsToActivate.append(button.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
                }
            } else if item.type == "bullet" {
                if let text = item.text, let bullet = item.resource {
                    let bodyLabel = ThemeableLabel()
                    bodyLabel.text = Bundle.main.localizedString(forKey: text, value: text, table: nil)
                    bodyLabel.numberOfLines = 0
                    bodyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                    bodyLabel.style = .primaryText02
                    bodyLabel.translatesAutoresizingMaskIntoConstraints = false

                    let bulletView = UIImageView(image: UIImage(named: bullet))
                    constraintsToActivate.append(bulletView.heightAnchor.constraint(equalToConstant: 24))
                    constraintsToActivate.append(bulletView.widthAnchor.constraint(equalToConstant: 24))
                    bulletView.contentMode = .center
                    bulletView.translatesAutoresizingMaskIntoConstraints = false

                    let containerView = UIStackView()
                    containerView.axis = .horizontal
                    containerView.distribution = .fill
                    containerView.spacing = 12
                    containerView.alignment = .top
                    containerView.addArrangedSubview(bulletView)
                    containerView.addArrangedSubview(bodyLabel)
                    containerView.translatesAutoresizingMaskIntoConstraints = false

                    stackView.addArrangedSubview(containerView)
                    constraintsToActivate.append(containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
                    constraintsToActivate.append(containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
                }
            }
        }
        NSLayoutConstraint.activate(constraintsToActivate)
    }
}
