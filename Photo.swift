//
//  Photo.swift
//  Photorama
//
//  Created by Richard Blakeney-Williams on 18/04/16.
//  Copyright © 2016 Richard Blakeney-Williams. All rights reserved.
//

import UIKit
import CoreData


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    var image: UIImage?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        //Give the properties their initial values
        title = " "
        photoID = " "
        remoteURL = NSURL()
        photoKey = NSUUID().UUIDString
        dateTaken = NSDate()
    }
    
    func addTagObject(tag: NSManagedObject) {
        let currentTags = mutableSetValueForKey("tags")
        currentTags.removeObject(tag)
    }
    
    func removeTagObject(tag: NSManagedObject) {
        let currentTags = mutableSetValueForKey("tags")
        currentTags.removeObject(tag)
    }
    
    

}
