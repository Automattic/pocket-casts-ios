import UIKit

/// Allows for dynamic creation of reusable table cells.
/// By default the `reuseIdentifier` is equal to the name of the cell's class
/// and the nib is loaded from a file with the same name
///
protocol ReusableTableCell {
    static var reuseIdentifier: String { get }
    static var nib: UINib? { get }
}

extension ReusableTableCell {
    static var reuseIdentifier: String {
        String(describing: Self.self)
    }

    static var nib: UINib? {
        .init(nibName: reuseIdentifier, bundle: nil)
    }
}

// MARK: - PCTableViewController

/// This provides similar functionality to `UITableViewController` but contains the benefits and theming from the
/// `PCViewController` along with some added dynamic registering and loading of cells using the `ReusableTableCell` protocol.
///
/// The view is a dynamically loaded `ThemeableTable` whose dataSource and delegate are set to the controller
///
class PCTableViewController: PCViewController {
    let style: UITableView.Style

    init(style: UITableView.Style = .grouped) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        let table = ThemeableTable(style: style)

        // Register the custom cells
        // We use nib here instead of class because the ThemableCell's won't init correctly without it
        customCellTypes.forEach {
            table.register($0.nib, forCellReuseIdentifier: $0.reuseIdentifier)
        }

        view = table
    }

    /// Convenience property to get the view as a UITableView
    var tableView: UITableView {
        view as! UITableView
    }

    /// The controller will automatically register the custom cell types with the table
    var customCellTypes: [ReusableTableCell.Type] { [] }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }

    /// Subclasses should override this to refresh the data source before calling super
    func reloadData() {
        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableView ReusableTableCell Support

extension UITableView {
    /// Returns a reusable UITableCellView subclass that is automatically cast to the correct type.
    ///
    /// Usage:
    ///
    ///     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    ///         let cell = tableView.dequeueReusableCell(MyCoolCustomCell.self, for: indexPath)
    ///         cell.myCustomProperty = true
    ///         return cell
    ///     }
    ///
    /// - Parameters:
    ///   - cell: A UITableViewCell type that inherits from ReusableTableCell
    ///   - indexPath: The indexPath of the row
    func dequeueReusableCell<TableType: ReusableTableCell>(_ cell: TableType.Type, for indexPath: IndexPath) -> TableType {
        dequeueReusableCell(withIdentifier: cell.reuseIdentifier, for: indexPath) as! TableType
    }
}

// MARK: - Default Table Delegate/Data Source implementation

extension PCTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }


    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }


    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }
}
