import UIKit
import MapKit
import CoreData
import CoreLocation

class AddressesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var createRouteButton: UIButton!
    @IBOutlet weak var showOnMapButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var titleArray = [String]()
    var idArray = [UUID]()
    var locations: [(title: String, latitude: Double, longitude: Double)] = []
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var deleteAllButton: UIBarButtonItem!
    
    // Track route creation state
    private var isRouteCreated = false
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocationManager()
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        setupNavigationBar()
        setupTableView()
        updateButtonStates()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .systemBlue
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))
        deleteAllButton = UIBarButtonItem(title: "Delete All", style: .plain, target: self, action: #selector(deleteAllButtonClicked))
        
        navigationItem.rightBarButtonItems = [addButton]
        navigationItem.leftBarButtonItems = [deleteAllButton]
        
        updateDeleteAllButtonState()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Button States Management
    private func updateButtonStates() {
        let shouldEnableCreateRoute = locations.count >= 2 && !isRouteCreated
        createRouteButton.isEnabled = shouldEnableCreateRoute
        createRouteButton.alpha = shouldEnableCreateRoute ? 1.0 : 0.5
        
        showOnMapButton.isEnabled = isRouteCreated
        showOnMapButton.alpha = isRouteCreated ? 1.0 : 0.5
    }
    
    private func updateDeleteAllButtonState() {
        deleteAllButton.isEnabled = !titleArray.isEmpty
    }
    
    // MARK: - Data Management
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            titleArray.removeAll(keepingCapacity: false)
            idArray.removeAll(keepingCapacity: false)
            locations.removeAll(keepingCapacity: false)
            
            for result in results as! [NSManagedObject] {
                if let title = result.value(forKey: "title") as? String,
                   let latitude = result.value(forKey: "latitude") as? Double,
                   let longitude = result.value(forKey: "longitude") as? Double,
                   let id = result.value(forKey: "id") as? UUID {
                    
                    titleArray.append(title)
                    idArray.append(id)
                    locations.append((title: title, latitude: latitude, longitude: longitude))
                }
            }
            
            // Eğer current location varsa kaldır
            locations.removeAll { $0.title == "Current Location" }
            
            isRouteCreated = false
            tableView.reloadData()
            updateDeleteAllButtonState()
            updateButtonStates()
            
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    
    // MARK: - Button Actions
    @objc func addButtonClicked() {
        // Alert controller oluştur
        let alert = UIAlertController(title: "Adres Ekle", message: "Adres ekleme yöntemini seçin", preferredStyle: .actionSheet)
        
        // Haritadan seçme seçeneği
        alert.addAction(UIAlertAction(title: "Haritadan Seç", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "toMapVC", sender: nil)
        })
        
        // Arama ile ekleme seçeneği
        alert.addAction(UIAlertAction(title: "Adres Ara", style: .default) { [weak self] _ in
            let addressSearchVC = AddressSearchVC()
            self?.navigationController?.pushViewController(addressSearchVC, animated: true)
        })
        
        // İptal seçeneği
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        3
        // iPad için popover presentation
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // Alert'i göster
        present(alert, animated: true)
    }
    
    @IBAction func createRouteButtonClicked(_ sender: Any) {
        guard !locations.isEmpty else { return }
        guard let userLocation = currentLocation else {
            showAlert(title: "Location Not Available", message: "Please enable location services to create an optimal route.")
            return
        }
        
        // Eğer zaten mevcutsa current location'ı kaldır
        locations.removeAll { $0.title == "Current Location" }
        
        // Optimal rotayı hesapla
        let optimalRoute = calculateOptimalRoute(
            currentLocation: userLocation,
            locations: locations
        )
        
        // Current location'ı sona ekle
        let currentLocationPoint = (
            title: "Current Location",
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )
        self.locations = optimalRoute + [currentLocationPoint]
        self.titleArray = self.locations.map { $0.title }
        
        tableView.reloadData()
        
        isRouteCreated = true
        updateButtonStates()
        
        showAlert(title: "Route Created", message: "The optimal route has been calculated.")
    }

    
    @IBAction func showOnMapButtonClicked(_ sender: Any) {
        let routeMapVC = RouteMapVC()
        routeMapVC.locations = self.locations
        routeMapVC.currentLocation = self.currentLocation
        navigationController?.pushViewController(routeMapVC, animated: true)
    }
    
    @objc func deleteAllButtonClicked() {
        let alert = UIAlertController(
            title: "Delete All",
            message: "Are you sure you want to delete all locations?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            self?.performDeleteAll()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func performDeleteAll() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results as! [NSManagedObject] {
                context.delete(result)
            }
            
            try context.save()
            
            titleArray.removeAll()
            idArray.removeAll()
            locations.removeAll()
            
            isRouteCreated = false
            tableView.reloadData()
            updateDeleteAllButtonState()
            updateButtonStates()
            
            showAlert(title: "Successful", message: "All locations have been deleted successfully.")
            
        } catch {
            print("Error deleting all locations: \(error)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Route Optimization Methods
    private func calculateOptimalRoute(
        currentLocation: CLLocation,
        locations: [(title: String, latitude: Double, longitude: Double)]
    ) -> [(title: String, latitude: Double, longitude: Double)] {
        
        // Create distance matrix
        let n = locations.count
        var distanceMatrix: [[Double]] = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        
        // Fill distance matrix
        for i in 0..<n {
            for j in 0..<n {
                if i != j {
                    distanceMatrix[i][j] = haversineDistance(
                        lat1: locations[i].latitude,
                        lon1: locations[i].longitude,
                        lat2: locations[j].latitude,
                        lon2: locations[j].longitude
                    )
                }
            }
        }
        
        // Find optimal route using 2-opt algorithm
        var route = Array(0..<n)
        var bestDistance = calculateTotalDistance(route: route, distanceMatrix: distanceMatrix)
        
        var improved = true
        while improved {
            improved = false
            
            for i in 0..<(route.count - 1) {
                for j in (i + 1)..<route.count {
                    let newRoute = twoOptSwap(route: route, i: i, j: j)
                    let newDistance = calculateTotalDistance(route: newRoute, distanceMatrix: distanceMatrix)
                    
                    if newDistance < bestDistance {
                        route = newRoute
                        bestDistance = newDistance
                        improved = true
                    }
                }
            }
        }
        
        // Return optimized route
        return route.map { locations[$0] }
    }
    
    private func twoOptSwap(route: [Int], i: Int, j: Int) -> [Int] {
        var newRoute = route
        // Reverse the segment between i and j
        let segment = Array(route[i...j].reversed())
        newRoute.replaceSubrange(i...j, with: segment)
        return newRoute
    }
    
    private func calculateTotalDistance(route: [Int], distanceMatrix: [[Double]]) -> Double {
        var totalDistance = 0.0
        
        for i in 0..<(route.count - 1) {
            totalDistance += distanceMatrix[route[i]][route[i + 1]]
        }
        
        return totalDistance
    }
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth's radius in kilometers
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            locationManager.stopUpdatingLocation()
        }
    }
    
    // MARK: - TableView Delegate & DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let rowNumber = indexPath.row + 1
        
        let locationCoordinate = CLLocation(
            latitude: locations[indexPath.row].latitude,
            longitude: locations[indexPath.row].longitude
        )
        
        if let userLocation = currentLocation {
            let distance = userLocation.distance(from: locationCoordinate) / 1000
            cell.textLabel?.text = "\(rowNumber). \(titleArray[indexPath.row])"
            cell.detailTextLabel?.text = String(format: "%.1f km", distance)
        } else {
            cell.textLabel?.text = "\(rowNumber). \(titleArray[indexPath.row])"
            cell.detailTextLabel?.text = "-- km"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let objectToDelete = results.first as? NSManagedObject {
                    context.delete(objectToDelete)
                    
                    titleArray.remove(at: indexPath.row)
                    idArray.remove(at: indexPath.row)
                    locations.remove(at: indexPath.row)
                    
                    // Eğer current location varsa kaldır
                    locations.removeAll { $0.title == "Current Location" }
                    
                    try context.save()
                    
                    isRouteCreated = false
                    
                    // Tablodaki ilgili satırı sil
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    updateDeleteAllButtonState()
                    updateButtonStates()
                }
            } catch {
                print("Error deleting location: \(error)")
            }
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toMapVC", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            if let destinationVC = segue.destination as? MapVC {
                if let selectedRow = tableView.indexPathForSelectedRow?.row {
                    destinationVC.selectedTitle = titleArray[selectedRow]
                    destinationVC.selectedTitleID = idArray[selectedRow]
                    
                    let location = locations[selectedRow]
                    destinationVC.chosenLatitude = location.latitude
                }
            }
        }
    }
}
