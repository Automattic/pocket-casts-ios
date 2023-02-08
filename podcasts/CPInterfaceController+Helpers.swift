import CarPlay
import PocketCastsUtils

extension CPInterfaceController {

    /// Shows the Now Playing template regardless of whether it's in the stack already or not.
    /// This will push to it if it's not already in the stack, or pop back to it if it is.
    func showNowPlaying() {
        let template = CPNowPlayingTemplate.shared

        // We can't push to it if it exists in the stack, so pop to it instead
        templates.contains(template) ? pop(to: template) : push(template)
    }

    /// Sets the root template of the controller, and will log any errors on failure
    func setRootTemplate(_ template: CPTemplate) {
        setRootTemplate(template, animated: true) { _, error in
            if let error {
                FileLog.shared.addMessage("[CarPlay] Could not set the root template to \(template.debugTitle). Error: \(error)")
            }
        }
    }

    /// Pops back to the given template, and will log any errors on failure
    func pop(to template: CPTemplate, animated: Bool = true) {
        pop(to: template, animated: true) { _, error in
            if let error {
                FileLog.shared.addMessage("[CarPlay] Could not pop to \(template.debugTitle). Error: \(error)")
            }
        }
    }

    /// Pushes to the given template, and will log any errors on failure
    func push(_ template: CPTemplate, animated: Bool = true) {
        pushTemplate(template, animated: true) { _, error in
            if let error {
                FileLog.shared.addMessage("[CarPlay] Could not push to \(template.debugTitle). Error: \(error)")
            }
        }
    }

    // popTemplate will throw an exception if no completion handler is present and a template can't be popped, so to work around that we have this method which captures the error and prints it since we don't particularly care
    func popTemplateIgnoringException() {
        popTemplate(animated: true) { _, error in
            if let error {
                FileLog.shared.addMessage("[CarPlay] Could not pop current template. Error: \(error)")
            }
        }
    }
}

// MARK: - Debug

extension CPTemplate {
    var debugTitle: String {
        var title: String?

        if let list = self as? CPListTemplate {
            title = list.title
        } else if let tabBar = self as? CPTabBarTemplate {
            title = tabBar.selectedTemplate?.debugTitle
        } else if (self as? CPNowPlayingTemplate) != nil {
            title = "Now Playing"
        } else {
            title = self.tabTitle
        }

        return "\(self.classForCoder).\(title ?? "none")"
    }
}
