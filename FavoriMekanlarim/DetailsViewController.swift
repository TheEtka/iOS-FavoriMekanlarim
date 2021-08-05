//
//  DetailsViewController.swift
//  FavoriMekanlarim
//
//  Created by Abdullah Etka Karadeniz  on 2.08.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class DetailsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mekanTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var kaydetButton: UIButton!
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenMekan = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // En Yakın Konum
        locationManager.requestWhenInUseAuthorization() // Uygulama kullanılırken konuma izin ver
        locationManager.startUpdatingLocation() // Konumu Güncel tut
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2 // Kullanıcı kaç saniye basılı tutsun
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenMekan != "" {
            
            kaydetButton.isHidden = true // Kaydet Button Gizle
            
            // CoreData'dan Verileri Çek...
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mekan")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let mekan = sonuc.value(forKey: "mekan") as? String {
                                annotationTitle = mekan
                                
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubTitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            mekanTextField.text = annotationTitle
                                            notTextField.text = annotationSubTitle
                                            
                                            locationManager.stopUpdatingLocation() // Konum güncellemeyi bırak
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("Hata!")
                }
            }
            
        } else {
            // Yeni Veri Ekleme
            kaydetButton.isHidden = false
            kaydetButton.isEnabled = false
        }
        // Klavyeyi Kapat
        let gestureRecognizerKlavye = UITapGestureRecognizer(target: self, action: #selector(klavyeyiKapat))
        view.addGestureRecognizer(gestureRecognizerKlavye)
    }
    
    @objc func klavyeyiKapat() {
        view.endEditing(true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "idAnnotation" // Annotation id
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .green
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenMekan != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizi, hata) in
                
                if let placemarks = placemarkDizi {
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = mekanTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
            
        }
        kaydetButton.isEnabled = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Haritayı, bulunulan konuma göre oynat
        if secilenMekan == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func kaydetButtonTiklandi(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniMekan = NSEntityDescription.insertNewObject(forEntityName: "Mekan", into: context)
        
        yeniMekan.setValue(mekanTextField.text, forKey: "mekan")
        yeniMekan.setValue(notTextField.text, forKey: "not")
        yeniMekan.setValue(secilenLatitude, forKey: "latitude")
        yeniMekan.setValue(secilenLongitude, forKey: "longitude")
        yeniMekan.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Kayıt Edildi")
        } catch {
            print("Hata!")
        }
        
        // Bildirim
        NotificationCenter.default.post(name: NSNotification.Name("yeniMekan"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}
