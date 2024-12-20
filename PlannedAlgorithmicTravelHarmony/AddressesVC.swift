import UIKit
import CoreData

class AddressesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var titleArray = [String]()
    var idArray = [UUID]()
    var locations: [(title: String, latitude: Double, longitude: Double)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))

        tableView.delegate = self
        tableView.dataSource = self

        getData()
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }

    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false

        do {
            let results = try context.fetch(request)

            if results.count > 0 {
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                self.locations.removeAll(keepingCapacity: false)

                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String,
                       let latitude = result.value(forKey: "latitude") as? Double,
                       let longitude = result.value(forKey: "longitude") as? Double,
                       let id = result.value(forKey: "id") as? UUID {

                        self.titleArray.append(title)
                        self.idArray.append(id)
                        self.locations.append((title: title, latitude: latitude, longitude: longitude))
                    }
                }
                tableView.reloadData()
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    @objc func addButtonClicked() {
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false

            do {
                let results = try context.fetch(fetchRequest)
                if let objectToDelete = results.first as? NSManagedObject {
                    context.delete(objectToDelete)
                    titleArray.remove(at: indexPath.row)
                    idArray.remove(at: indexPath.row)
                    locations.remove(at: indexPath.row)

                    try context.save()
                    tableView.reloadData()
                }
            } catch {
                print("Error deleting location: \(error)")
            }
        }
    }

    @IBAction func createRouteButtonClicked(_ sender: Any) {
        guard locations.count > 1 else {
            let alert = UIAlertController(title: "Not Enough Locations", message: "Please add at least 2 locations with valid coordinates.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        let optimalRoute = calculateOptimalRoute(locations: locations)
        self.titleArray = optimalRoute.map { $0.title }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }

        let alert = UIAlertController(title: "Route Created", message: "The locations have been sorted in an optimal route.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func calculateOptimalRoute(locations: [(title: String, latitude: Double, longitude: Double)]) -> [(title: String, latitude: Double, longitude: Double)] {
        var unvisited = locations
        var route: [(title: String, latitude: Double, longitude: Double)] = []

        if let startLocation = unvisited.first {
            route.append(startLocation)
            unvisited.removeFirst()
        }

        while !unvisited.isEmpty {
            if let lastVisited = route.last {
                unvisited.sort { location1, location2 in
                    haversineDistance(lat1: lastVisited.latitude, lon1: lastVisited.longitude, lat2: location1.latitude, lon2: location1.longitude) <
                    haversineDistance(lat1: lastVisited.latitude, lon1: lastVisited.longitude, lat2: location2.latitude, lon2: location2.longitude)
                }
                if let nearest = unvisited.first {
                    route.append(nearest)
                    unvisited.removeFirst()
                }
            }
        }

        if let startLocation = route.first {
            route.append(startLocation)
        }

        return route
    }

    func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * Double.pi / 180
        let dLon = (lon2 - lon1) * Double.pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * Double.pi / 180) * cos(lat2 * Double.pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}
