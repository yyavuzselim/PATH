import UIKit
import MapKit
import CoreLocation
import CoreData

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var isPinAdded = false // Pin eklenip eklenmediğini takip eden değişken
    var selectedTitle = ""
    var selectedTitleID: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizerVC = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        mapView.addGestureRecognizer(gestureRecognizerVC)
        
        // MapView ve LocationManager Ayarları
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // TextField Kontrolü
        commentText.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        nameText.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        
        // Save butonu başlangıçta inaktif
        setSaveButtonState(isEnabled: false)
        
        // Uzun basma ile pin ekleme
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        // Eğer kayıtlı bir adres açılıyorsa
        if selectedTitle != "" {
            loadExistingData()
        }
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    
    // MARK: - Save Butonu Aktif/Pasif Kontrolü
    @objc func textFieldsDidChange() {
        checkSaveButtonStatus()
    }
    
    func checkSaveButtonStatus() {
        // Text alanlarının doluluğunu ve pin eklenip eklenmediğini kontrol eder
        if let name = nameText.text, let comment = commentText.text, !name.isEmpty, !comment.isEmpty, isPinAdded {
            setSaveButtonState(isEnabled: true)
        } else {
            setSaveButtonState(isEnabled: false)
        }
    }
    
    func setSaveButtonState(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    // MARK: - Uzun Basma ile Pin Ekleme
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            
            // Önceki pinleri kaldır
            mapView.removeAnnotations(mapView.annotations)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            isPinAdded = true // Pin eklendi
            
            // Yeni pin oluştur
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            mapView.addAnnotation(annotation)
            
            checkSaveButtonStatus()
        }
    }
    
    // MARK: - Core Data'dan Veri Yükleme
    func loadExistingData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        let idString = selectedTitleID!.uuidString
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String,
                       let subtitle = result.value(forKey: "subtitle") as? String,
                       let latitude = result.value(forKey: "latitude") as? Double,
                       let longitude = result.value(forKey: "longitude") as? Double {
                        
                        let annotation = MKPointAnnotation()
                        annotation.title = title
                        annotation.subtitle = subtitle
                        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        
                        mapView.addAnnotation(annotation)
                        nameText.text = title
                        commentText.text = subtitle
                        isPinAdded = true
                        
                        // Harita konumunu ayarla
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                        locationManager.stopUpdatingLocation()
                    }
                }
            }
        } catch {
            print("Error fetching data")
        }
        
        // Save butonunu gizle
        saveButton.isHidden = true
    }
    
    // MARK: - Save Butonu
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Success saving data")
        } catch {
            print("Error saving data")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Lokasyon Takibi
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            locationManager.stopUpdatingLocation()
        }
    }
    
    // MARK: - Pin Seçme Kontrolü
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // Pin'e tıklanabilir bilgi kısmı ekler.
            pinView?.tintColor = UIColor.black
            
            // Sağda "i" butonu ekleniyor
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // "i" butonuna tıklanırsa
        if let annotation = view.annotation {
            let requestLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks, placemark.count > 0 {
                    let newPlacemark = MKPlacemark(placemark: placemark[0])
                    let item = MKMapItem(placemark: newPlacemark)
                    item.name = annotation.title ?? "Hedef Konum"
                    
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions: launchOptions) // Harita yönlendirmesini başlatır
                }
            }
        }
    }

}
