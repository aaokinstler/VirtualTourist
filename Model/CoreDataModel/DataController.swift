//
//  DataController.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 09.08.2021.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer = NSPersistentContainer(name: "VirtualTourist")
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    var backgroundContext: NSManagedObjectContext!
   
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            completion?()
        }
    }
}
