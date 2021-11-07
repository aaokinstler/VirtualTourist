//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 04.08.2021.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var album: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    var locationID: NSManagedObjectID!
    var location: Location!
    var dataController: DataController!
    var fetchedResultController: NSFetchedResultsController<Photo>!
    var datasource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!
    var saveObserverToken: Any?
    
    fileprivate func setFetchedResultController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "location == %@", location)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photo")
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            fatalError("The fetch could note be performed:  \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        location = dataController.viewContext.object(with: locationID) as? Location
        configureDatasource()
        addSaveNotificationObserver()
        album.delegate = self
        
        setFetchedResultController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        setMapView()
        setAlbumView()
        setNewCollectionButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSaveNotificationObserver()
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        let downloadingManager = PhotoDownloadingManager(locationID: locationID, dataController: dataController)
        downloadingManager.reloadPhotosForLocation()
    }
    
    func setNewCollectionButton() {
        newCollectionButton.isHidden = !location.photosDownloaded
    }
    
    func addSaveNotificationObserver() {
        removeSaveNotificationObserver()
        saveObserverToken =  NotificationCenter.default.addObserver(self, selector: #selector (handlePhotosDownloadNotification(_ :)), name: .NSManagedObjectContextDidMergeChangesObjectIDs, object: dataController.viewContext)
    }
    
    func removeSaveNotificationObserver() {
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    func setMapView() {
        mapView.addAnnotation(location)
        let regionRadius: CLLocationDistance = 100000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func setAlbumView() {
        let albumFlowLayout = UICollectionViewFlowLayout()
        let cellWidthHeight = view.frame.width / 3
        albumFlowLayout.itemSize = CGSize(width: cellWidthHeight, height: cellWidthHeight)
        albumFlowLayout.minimumInteritemSpacing = 0
        albumFlowLayout.minimumLineSpacing = 0
        album.collectionViewLayout = albumFlowLayout
    }
    
    func configureDatasource() {
        datasource = UICollectionViewDiffableDataSource(collectionView: album, cellProvider: configureCell(_:indexPath:identifier:))
        album.dataSource = datasource
    }
    
    @objc func handlePhotosDownloadNotification(_ notification: NSNotification) {
        if let updated = notification.userInfo?[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID>,
           updated.contains(location.objectID){
            setNewCollectionButton()
        }
    }
}


extension AlbumViewController: UICollectionViewDelegate {
    
    @objc func configureCell(_ collectionView: UICollectionView,  indexPath: IndexPath, identifier: Any) -> UICollectionViewCell {
        let photoObject = fetchedResultController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo", for: indexPath) as! CollectionViewCell
        
        if let imageData = photoObject.image {
            cell.imageView.image = UIImage(data: imageData)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        location.numberOfPhotos -= 1
        location.numberOfDownloadedPhotos -= 1
        try? dataController.viewContext.save()
    }
}

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        datasource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: false)
    }
}
