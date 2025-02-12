import UIKit
import CoreData
import MapKit
import CoreLocation

class AddressSearchVC: UIViewController {
    
    // MARK: - UI Elements
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Adres ara..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: - Properties
    private var searchCompleter: MKLocalSearchCompleter
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedLocation: CLLocationCoordinate2D?
    private var selectedAddress: String?
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.searchCompleter = MKLocalSearchCompleter()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.searchCompleter.delegate = self
        self.searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        
        // Konum izni kontrolü
        locationManager.requestWhenInUseAuthorization()
        
        // Kullanıcının konumuna göre arama bölgesini ayarla
        if let userLocation = locationManager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            self.searchCompleter.region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // TableView ayarları
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    private func setupNavigationBar() {
        title = "Adres Ara"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Kaydet",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // MARK: - Actions
    @objc private func saveButtonTapped() {
        guard let coordinate = selectedLocation,
              let address = selectedAddress else { return }
        
        // Core Data'ya kaydet
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(address, forKey: "title")
        newPlace.setValue("Tam Adres", forKey: "subtitle")
        newPlace.setValue(coordinate.latitude, forKey: "latitude")
        newPlace.setValue(coordinate.longitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
            navigationController?.popViewController(animated: true)
        } catch {
            let alert = UIAlertController(
                title: "Hata",
                message: "Adres kaydedilemedi",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func searchAddress(for searchCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: searchCompletion)
        searchRequest.resultTypes = [.address, .pointOfInterest]
        searchRequest.naturalLanguageQuery = searchCompletion.title + " " + searchCompletion.subtitle
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] (response, error) in
            guard let self = self,
                  let mapItem = response?.mapItems.first else {
                // Sonuç bulunamadıysa alternatif arama yap
                self?.performAlternativeSearch(searchText: searchCompletion.title)
                return
            }
            
            let coordinate = mapItem.placemark.coordinate
            
            // Detaylı adres bilgisi oluştur
            var addressComponents: [String] = []
            
            if let name = mapItem.name { addressComponents.append(name) }
            if let subThoroughfare = mapItem.placemark.subThoroughfare { addressComponents.append(subThoroughfare) }
            if let thoroughfare = mapItem.placemark.thoroughfare { addressComponents.append(thoroughfare) }
            if let subLocality = mapItem.placemark.subLocality { addressComponents.append(subLocality) }
            if let locality = mapItem.placemark.locality { addressComponents.append(locality) }
            
            let fullAddress = addressComponents.joined(separator: ", ")
            
            self.selectedLocation = coordinate
            self.selectedAddress = fullAddress
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            // Seçilen adresi göster
            let alert = UIAlertController(
                title: "Adres Seçildi",
                message: fullAddress,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func performAlternativeSearch(searchText: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] (response, error) in
            guard let self = self,
                  let mapItem = response?.mapItems.first else { return }
            
            let coordinate = mapItem.placemark.coordinate
            
            // Detaylı adres bilgisi oluştur
            var addressComponents: [String] = []
            
            if let name = mapItem.name { addressComponents.append(name) }
            if let subThoroughfare = mapItem.placemark.subThoroughfare { addressComponents.append(subThoroughfare) }
            if let thoroughfare = mapItem.placemark.thoroughfare { addressComponents.append(thoroughfare) }
            if let subLocality = mapItem.placemark.subLocality { addressComponents.append(subLocality) }
            if let locality = mapItem.placemark.locality { addressComponents.append(locality) }
            
            let fullAddress = addressComponents.joined(separator: ", ")
            
            self.selectedLocation = coordinate
            self.selectedAddress = fullAddress
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            // Seçilen adresi göster
            let alert = UIAlertController(
                title: "Adres Seçildi",
                message: fullAddress,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UISearchBarDelegate
extension AddressSearchVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults.removeAll()
            tableView.reloadData()
            return
        }
        searchCompleter.queryFragment = searchText
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddressSearchVC: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Arama tamamlama hatası: \(error.localizedDescription)")
    }
}

// MARK: - UITableViewDelegate & DataSource
extension AddressSearchVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        
        // Value1 stili kullan
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = searchResult.title
            content.secondaryText = searchResult.subtitle
            content.textProperties.numberOfLines = 0
            content.secondaryTextProperties.numberOfLines = 0
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = searchResult.title
            cell.detailTextLabel?.text = searchResult.subtitle
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = searchResults[indexPath.row]
        searchAddress(for: selection)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
