

import CoreData
import UIKit

class PhotoDownloadingManager {
    
    let location: Location
    let backgroundContext: NSManagedObjectContext
    
    init(locationID: NSManagedObjectID, dataController: DataController) {
        backgroundContext = dataController.backgroundContext
        location = backgroundContext.object(with: locationID) as! Location
    }
    
    func reloadPhotosForLocation()  {
        backgroundContext.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
            let predicate = NSPredicate(format: "location == %@", self.location)
            fetchRequest.predicate = predicate
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try backgroundContext.execute(batchDeleteRequest)
            } catch {
                print(error.localizedDescription)
            }
            
            location.downloadingPhotos = true
            location.numberOfDownloadedPhotos = 0
            location.numberOfPhotos = 0
            location.photosDownloaded = false
            
            do {
                try backgroundContext.save()
            } catch {
                print(error.localizedDescription)
            }
            
            FlickrClient.getURLsForCoordinates(location: location, completion: handleURLsDownloading(urlArray:error:))
        }
    }
    
    func downloadPhotosForLocation() {
        backgroundContext.performAndWait {
            location.downloadingPhotos = true
            do {
                try backgroundContext.save()
            } catch {
                print(error.localizedDescription)
            }
                
            FlickrClient.getURLsForCoordinates(location: location, completion: handleURLsDownloading(urlArray:error:))
        }
    }
    
    func handleURLsDownloading(urlArray: [String]?, error: String?) {
        guard let urlArray = urlArray else {
            return
        }
        
        urlArray.forEach() { photoUrl in
            let newPhoto = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: self.backgroundContext)
            newPhoto.setValue(photoUrl, forKey: "url")
            newPhoto.setValue(self.location, forKey: "location")
        }
        
        location.numberOfPhotos = Int16(urlArray.count)
        location.numberOfDownloadedPhotos = 0
        
        do {
            try self.backgroundContext.save()
        } catch {
            print(error.localizedDescription)
        }
        
        let photoObjects = self.location.photos?.allObjects as! [Photo]
        downloadImages(photoObjects: photoObjects)
    }
    
    private func downloadImages(photoObjects: [Photo]) {
        
        photoObjects.forEach() { photo in
            let url = photo.url
            let id =  photo.objectID
            FlickrClient.downloadImage(url: URL(string: url!)!, photoID: id, completion: handleDowlnloadingImageData(data:objectID:error:))
            
        }
    }
    
    private func handleDowlnloadingImageData(data: Data?, objectID: NSManagedObjectID, error: String?) {
        guard let data = data else {
            increasePhotoCounter()
            try! self.backgroundContext.save()
            return
        }
        
        let photoObject = backgroundContext.object(with: objectID) as! Photo
        photoObject.image = data
        increasePhotoCounter()
        
        
    }
    
    private func increasePhotoCounter() {
        location.numberOfDownloadedPhotos += 1
        
        if location.numberOfDownloadedPhotos % 50 == 0 {
            try! self.backgroundContext.save()
        }
        
        if location.numberOfPhotos == location.numberOfDownloadedPhotos {
            location.downloadingPhotos = false
            location.photosDownloaded = true
            try! self.backgroundContext.save()
        }
    }
}
