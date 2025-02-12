import UIKit

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Section Models
    private struct Section {
        let title: String
        let options: [SettingOption]
    }

    private struct SettingOption {
        let title: String
        let icon: String // SF Symbols name
        let iconBackgroundColor: UIColor
        let handler: (() -> Void)?
    }

    // MARK: - Data Source
    private var sections: [Section] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureSettings()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Settings"

        // TableView setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)

        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
    }

    // MARK: - Settings Configuration
    private func configureSettings() {
        sections = [
            // Account Section
            Section(title: "Account", options: [
                SettingOption(
                    title: "Log Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    iconBackgroundColor: .systemRed,
                    handler: { [weak self] in
                        self?.logOutButtonClicked()
                    }
                )
            ])
        ]
    }

    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].options.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let option = sections[indexPath.section].options[indexPath.row]

        // Configure cell
        var content = cell.defaultContentConfiguration()
        content.text = option.title

        // Create icon configuration
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        content.image = UIImage(systemName: option.icon, withConfiguration: imageConfig)
        content.imageProperties.tintColor = .white

        // Create background for icon
        let iconBackground = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        iconBackground.backgroundColor = option.iconBackgroundColor
        iconBackground.layer.cornerRadius = 6
        content.imageProperties.reservedLayoutSize = CGSize(width: 30, height: 30)

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = sections[indexPath.section].options[indexPath.row]
        option.handler?()
    }

    // MARK: - Action Handlers
    @IBAction func logOutButtonClicked() {
        let alert = UIAlertController(title: "Log Out", message: "Do you want to log out?", preferredStyle: .alert)

        let ok = UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            self?.performSegue(withIdentifier: "toLogInVC", sender: nil)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
}
