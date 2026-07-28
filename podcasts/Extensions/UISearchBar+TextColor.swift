public extension UISearchBar {
    func pc_setTextColor(_ color: UIColor) {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: color]
    }
}
