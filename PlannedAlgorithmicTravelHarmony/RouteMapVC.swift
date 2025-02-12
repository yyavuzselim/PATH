import UIKit
import MapKit
import CoreLocation

class RouteMapVC: UIViewController, MKMapViewDelegate {
    
    var mapView: MKMapView!
    var locations: [(title: String, latitude: Double, longitude: Double)] = []
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MapView'i programmatically oluştur
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        // Başlangıç bölgesini ayarla
        setInitialRegion()
        
        // Tüm pinleri ekle ve rotayı çiz
        addAnnotationsAndDrawRoute()
    }
    
    func setInitialRegion() {
        if let currentLoc = currentLocation {
            // Mevcut konuma göre başlangıç bölgesi
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: currentLoc.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            // Varsayılan başlangıç bölgesi (örnek: İstanbul)
            let defaultLocation = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: defaultLocation, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func addAnnotationsAndDrawRoute() {
        var annotations: [MKPointAnnotation] = []
        
        // Mevcut konumu ekle
        if let currentLoc = currentLocation {
            let currentAnnotation = MKPointAnnotation()
            currentAnnotation.coordinate = currentLoc.coordinate
            currentAnnotation.title = "0. Mevcut Konumunuz"
            annotations.append(currentAnnotation)
            mapView.addAnnotation(currentAnnotation)
        }
        
        // Tüm lokasyonlar için pin ekle
        for (index, location) in locations.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = "\(index + 1). \(location.title)"
            annotations.append(annotation)
            mapView.addAnnotation(annotation)
        }
        
        // Rota çizimi için directions request oluştur
        if annotations.count >= 2 {
            for i in 0..<(annotations.count - 1) {
                let sourceAnnotation = annotations[i]
                let destinationAnnotation = annotations[i + 1]
                
                let sourcePlacemark = MKPlacemark(coordinate: sourceAnnotation.coordinate)
                let destinationPlacemark = MKPlacemark(coordinate: destinationAnnotation.coordinate)
                
                let directionRequest = MKDirections.Request()
                directionRequest.source = MKMapItem(placemark: sourcePlacemark)
                directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
                directionRequest.transportType = .automobile
                
                let directions = MKDirections(request: directionRequest)
                directions.calculate { [weak self] response, error in
                    guard let self = self, let response = response else { return }
                    
                    let route = response.routes[0]
                    self.mapView.addOverlay(route.polyline)
                    
                    // Tüm rotaları gösterecek şekilde haritayı ayarla
                    if i == 0 {
                        let rect = route.polyline.boundingMapRect
                        self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                    }
                }
            }
        }
    }
    
    // Rota çizgisi için delegate metodu
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // Pin görünümü için delegate metodu
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            
            // Pin'e "i" butonu ekle
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            // Eğer mevcut konum ise farklı renk kullan
            if annotation.title??.starts(with: "0.") == true {
                pinView?.markerTintColor = .red
            } else {
                pinView?.markerTintColor = .blue
            }
            pinView?.glyphTintColor = .white
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    // "i" butonuna tıklandığında navigasyon başlat
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let coordinate = view.annotation?.coordinate {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = view.annotation?.title ?? "Hedef"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
}
