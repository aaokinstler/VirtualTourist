//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 03.08.2021.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longTap: UILongPressGestureRecognizer!
    
    var dataController: DataController!
    var fetchedResultController: NSFetchedResultsController<Location>!
    
    fileprivate func setFetchedResultController() {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "locations")
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            fatalError("The fetch could note be performed:  \(error.localizedDescription)")
        }
    }
    
    func initializeMap() {
        if mapView.annotations.count > 0 {
            mapView.removeAnnotations(mapView.annotations)
        }
        
        if let locations = fetchedResultController.fetchedObjects {
            for location in locations {
                mapView.addAnnotation(location)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        setFetchedResultController()
        initializeMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultController = nil
    }
    
    @IBAction func longTapRecognised(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let translation = sender.location(in: mapView)
            let translationCoordinate: CLLocationCoordinate2D = mapView.convert(translation, toCoordinateFrom: self.mapView)
            let location = Location(context: dataController.viewContext)
            location.latitude = translationCoordinate.latitude
            location.longitude = translationCoordinate.longitude
            try? dataController.viewContext.save()
            
            let locationID =  location.objectID
            let downloadingManager = PhotoDownloadingManager(locationID: locationID, dataController: dataController)
            downloadingManager.downloadPhotosForLocation()
        }
    }
    
    
    func showFailure(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlbumViewController {
            vc.dataController = dataController
            let location = mapView.selectedAnnotations[0] as! Location
            vc.locationID = location.objectID
        }
    }
}


extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "showAlbum", sender: self)
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let point = anObject as? Location else {
            preconditionFailure("All changes observed in the map view controller should be for Point instances")
        }
        
        switch type {
        case .insert:
            mapView.addAnnotation(point)
        case .delete:
            mapView.removeAnnotation(point)
        case .update:
            mapView.removeAnnotation(point)
            mapView.addAnnotation(point)
        case .move:
            fatalError("We can't move dots")
        @unknown default:
            fatalError("cant handle result change type")
        }
    }
}

