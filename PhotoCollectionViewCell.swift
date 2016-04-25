//
//  PhotoCollectionViewCell.swift
//  Photorama
//
//  Created by Richard Blakeney-Williams on 15/04/16.
//  Copyright © 2016 Richard Blakeney-Williams. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    
    func updateWithImage(image: UIImage?){
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
    
    
    override func awakeFromNib() {
        super.prepareForReuse()
        
        updateWithImage(nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateWithImage(nil)
    }
    
}


