//
//  PhotoStore.swift
//  Photorama
//
//  Created by Richard Blakeney-Williams on 13/04/16.
//  Copyright © 2016 Richard Blakeney-Williams. All rights reserved.
//

import UIKit
import CoreData


enum ImageResult {
    case Success(UIImage)
    case Failure(ErrorType)
}

enum PhotoError: ErrorType {
    case ImageCreationError
}

class PhotoStore {
    
    let coreDataStack = CoreDataStack(modeName: "Photorama")
    let imageStore = ImageStore()

    
    let session: NSURLSession = {
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: config)
    }()
    
    func fetchMainQueuePhotos(predicate predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Photo] {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        
        let mainQueueContext = self.coreDataStack.mainQueueContext
        var mainQueuePhotos: [Photo]?
        var fetchRequestError: ErrorType?
        mainQueueContext.performBlockAndWait() {
            do {
                mainQueuePhotos =
                try mainQueueContext.executeFetchRequest(fetchRequest) as? [Photo]
            }
            catch let error {
                fetchRequestError = error
            }
        }
        guard let photos = mainQueuePhotos else {
            throw fetchRequestError!
        }
        
        return photos
    }
    
    
    //Method to download the image data. Takes a completion closure that will return an imageResult
    func fetchImageForPhoto(photo: Photo, completion: (ImageResult) -> Void) {
        
        //Check if the photo has already been downloaded.
        if let image = photo.image{
            completion(.Success(image))
            return
        }
        
        
        let photoURL = photo.remoteURL
        let request = NSURLRequest(URL: photoURL)
        
        let task = session.dataTaskWithRequest(request){
            (data,response,error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error)
            
            if case let .Success(image) = result {
                photo.image = image
            }
            
            completion(result)
            
        }
        task.resume()
    }
    
    //Processes the data from the web service request into an image
    func processImageRequest(data data: NSData?, error: NSError?) -> ImageResult {
        guard let
            imageData = data,
            image = UIImage(data: imageData) else {
                //Couldn't create an image 
                if data == nil {
                    return .Failure(error!)
                }
                else {
                    return .Failure(PhotoError.ImageCreationError)
                }
        }
        return .Success(image)
    }
    
    func fetchMainQueueTags(predicate predicate: NSPredicate? = nil,
                                      sortDescriptors: [NSSortDescriptor]? = nil) throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: "Tag")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        let mainQueueContext = self.coreDataStack.mainQueueContext
        var mainQueueTags: [NSManagedObject]?
        var fetchRequestError: ErrorType?
        mainQueueContext.performBlockAndWait({
            do {
                mainQueueTags = try mainQueueContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            }
            catch let error {
                fetchRequestError = error
            }
        })
        
        guard let tags = mainQueueTags else {
            throw fetchRequestError!
        }
        
        return tags
    }
    
    
    func processRecentPhotosRequest(data data: NSData?, error: NSError?) -> PhotoResult{
        guard let jsonData = data else {
            return .Failure(error!)
        }
        
        return FlickrAPI.photosFromJSONData(jsonData, inContext: self.coreDataStack.privateQueueContext)
    }
    
    
    func fetchRecentPhotos(completion completion: (PhotoResult) -> Void) {
        let url = FlickrAPI.recentPhotosURL()
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request){
            (data,response,error) -> Void in
            
            var result = self.processRecentPhotosRequest(data: data, error: error)
            
            if case let .Success(photos) = result {
                let privateQueueContext = self.coreDataStack.privateQueueContext
                privateQueueContext.performBlockAndWait(){
                    try! privateQueueContext.obtainPermanentIDsForObjects(photos)
                }
                let objectIds = photos.map{$0.objectID}
                let predicate = NSPredicate(format: "self IN %@", objectIds)
                let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
               
                do {
                    try self.coreDataStack.saveChanges()
                    let mainQueuePhotos = try self.fetchMainQueuePhotos(predicate: predicate, sortDescriptors: [sortByDateTaken])
                    result = .Success(mainQueuePhotos)
                }
                catch let error {
                    result = .Failure(error)
                }
            }
            completion(result)
        }
        task.resume()
    }
    
    
}
