import PocketCastsDataModel
import PocketCastsServer
import UIKit

extension AccountViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else {
            return UITableView.automaticDimension
        }

        return headerViewModel.contentSize?.height ?? UITableView.automaticDimension
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableData[indexPath.section][indexPath.row]
        switch row {
        case .upgradeView:
            return upgradePromptViewSize?.height ?? UITableView.automaticDimension

        case .newsletter:
            return UITableView.automaticDimension
        default:
            return 64
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableData[indexPath.section][indexPath.row]
        switch row {
        case .upgradeView:
            return 350
        default:
            return 64
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableData[indexPath.section][indexPath.row]

        switch row {
        case .upgradeView:
            let cell = tableView.dequeueReusableCell(withIdentifier: PlusAccountPromptTableCell.reuseIdentifier, for: indexPath) as! PlusAccountPromptTableCell
            cell.updateParent(self)
            cell.contentSizeUpdated = { [weak self] size in
                self?.upgradePromptViewSize = size
            }

            return cell

        case .supporterContributions:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.supporterContributions
            cell.cellImage.image = UIImage(named: "account-heart")
            cell.iconStyle = .primaryInteractive01

            let activeSubscriptionsCount = SubscriptionHelper.numActiveSubscriptionBundles()
            if activeSubscriptionsCount > 0 {
                cell.counterView.isHidden = false
                cell.counterLabel.text = "\(activeSubscriptionsCount)"
            } else {
                cell.counterView.isHidden = true
            }
            cell.showsDisclosureIndicator = true
            return cell
        case .changeEmail:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.accountChangeEmail
            cell.cellImage.image = UIImage(named: "mail")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false
            return cell
        case .changePassword:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.changePassword
            cell.cellImage.image = UIImage(named: "key")
            cell.iconStyle = .primaryInteractive01
            cell.showsDisclosureIndicator = false
            cell.counterView.isHidden = true
            return cell
        case .newsletter:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.newsletterCellId, for: indexPath) as! NewsletterCell
            cell.cellSwitch.setOn(ServerSettings.marketingOptIn(), animated: false)
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(newsletterOptInChanged(_:)), for: UIControl.Event.valueChanged)
            cell.iconStyle = .primaryInteractive01
            return cell
        case .deleteAccount:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.accountDeleteAccount
            cell.cellImage.image = UIImage(named: "delete")
            cell.iconStyle = .support05
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false
            return cell
        case .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.accountSignOut
            cell.cellImage.image = UIImage(named: "signout")
            cell.iconStyle = .support05
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false

            return cell
        case .cancelSubscription:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.cancelSubscription
            cell.cellImage.image = UIImage(named: "cancelsubscription")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false
            return cell
        case .privacyPolicy:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.accountPrivacyPolicy
            cell.cellImage.image = UIImage(named: "privacypolicy")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false
            return cell
        case .termsOfUse:
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewController.actionCellId, for: indexPath) as! AccountActionCell
            cell.cellLabel.text = L10n.termsOfUse
            cell.cellImage.image = UIImage(named: "termsconditions")
            cell.iconStyle = .primaryInteractive01
            cell.counterView.isHidden = true
            cell.showsDisclosureIndicator = false
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = tableData[indexPath.section][indexPath.row]

        if row == .newsletter {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = tableData[indexPath.section][indexPath.row]

        switch row {
        case .upgradeView:
            break

        case .supporterContributions:
            let supporterVC = SupporterContributionsViewController()
            navigationController?.pushViewController(supporterVC, animated: true)
        case .changeEmail:
            let changeEmailVC = ChangeEmailViewController()
            changeEmailVC.delegate = self
            present(SJUIUtils.popupNavController(for: changeEmailVC), animated: true, completion: nil)
        case .changePassword:
            let changePasswordVC = ChangePasswordViewController()
            present(SJUIUtils.popupNavController(for: changePasswordVC), animated: true, completion: nil)
        case .newsletter:
            break
        case .logout:
            showSignOutWarning()
        case .deleteAccount:
            deleteAccountTapped()
        case .cancelSubscription:
            let controller = CancelConfirmationViewModel.make()

            present(controller, animated: true, completion: nil)
            Analytics.track(.accountDetailsCancelTapped)
        case .privacyPolicy:
            NavigationManager.sharedManager.navigateTo(NavigationManager.showPrivacyPolicyPageKey, data: nil)
            Analytics.track(.accountDetailsShowPrivacyPolicy)
        case .termsOfUse:
            NavigationManager.sharedManager.navigateTo(NavigationManager.showTermsOfUsePageKey, data: nil)
            Analytics.track(.accountDetailsShowTOS)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func showSignOutWarning() {
        let numSubscriptionPodcasts = DataManager.sharedManager.allPaidPodcasts().count

        let signOutAction = OptionAction(label: L10n.accountSignOut, icon: "signout") { [weak self] in
            SignOutHelper.signout()
            self?.navigationController?.popViewController(animated: true)
        }
        signOutAction.destructive = true

        if numSubscriptionPodcasts > 0 {
            let options = OptionsPicker(title: "", iconTintStyle: .support05)
            options.addDescriptiveActions(title: L10n.accountSignOut, message: L10n.accountSignOutSupporterPrompt(numSubscriptionPodcasts.localized()) + "\n\n" + L10n.accountSignOutSupporterSubtitle, icon: "signout", actions: [signOutAction])

            options.show(statusBarStyle: preferredStatusBarStyle)
        } else {
            let options = OptionsPicker(title: L10n.areYouSure)
            options.addAction(action: signOutAction)

            options.show(statusBarStyle: preferredStatusBarStyle)
        }
    }

    private func deleteAccountTapped() {
        let firstAlert = UIAlertController(title: L10n.accountDeleteAccountTitle, message: L10n.accountDeleteAccountFirstAlertMsg, preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { [weak self] _ in
            let finalAlert = UIAlertController(title: L10n.accountDeleteAccountTitle, message: L10n.accountDeleteAccountFinalAlertMsg, preferredStyle: .alert)

            let deleteAction = UIAlertAction(title: L10n.accountDeleteAccountConf, style: .destructive) { [weak self] _ in
                ApiServerHandler.shared.deleteAccount { success, errorMessage in
                    if !success {
                        let message = errorMessage ?? L10n.accountDeleteAccountErrorMsg
                        SJUIUtils.showAlert(title: L10n.accountDeleteAccountError, message: message, from: self)

                        return
                    }

                    DispatchQueue.main.async {
                        Analytics.track(.userAccountDeleted)
                        AnalyticsHelper.accountDeleted()
                        SignOutHelper.signout()

                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
            finalAlert.addAction(deleteAction)

            let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
            finalAlert.addAction(cancelAction)

            self?.present(finalAlert, animated: true, completion: nil)
        }
        firstAlert.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
        firstAlert.addAction(cancelAction)

        present(firstAlert, animated: true, completion: nil)
    }
}
