//
//  PhotoViewer.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/16/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation
import NYTPhotoViewer

class PhotoProvider: NSObject, NYTPhotoViewerDataSource {
    private let photo: Photo
    
    lazy var photoViewer: NYTPhotosViewController = {
        return NYTPhotosViewController(dataSource: self)
    }()
    
    init(image: UIImage) {
        self.photo = Photo(image: image)
    }
    
    @objc
    var numberOfPhotos: NSNumber? {
        return 1
    }
    
    @objc
    func index(of photo: NYTPhoto) -> Int {
        return 0
    }
    
    @objc
    func photo(at index: Int) -> NYTPhoto? {
        return photo
    }
}

class Photo: NSObject, NYTPhoto {
    var image: UIImage?
    var imageData: Data?
    var placeholderImage: UIImage?
    
    var attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString?
    var attributedCaptionCredit: NSAttributedString?
    
    init(image: UIImage) {
        self.image = image
    }
}

