//
//  GeneralUtils.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/3/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation
import UIKit

class GeneralUtils {
    static func getInitials(for userName: String) -> String {
        let words = userName.split(separator: " ", maxSplits: 2)
        switch words.count {
        case 2:
            return words.map( { $0.prefix(1) }).joined()
        default:
            return String(userName.prefix(2))
        }
    }
    
    static func createLabeledImage(width: CGFloat, height: CGFloat, text: String, fontSize: CGFloat, labelBackgroundColor: UIColor, labelTextColor: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let label = UILabel(frame: rect)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        label.backgroundColor = labelBackgroundColor
        label.textColor = labelTextColor
        UIGraphicsBeginImageContext(rect.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            label.layer.render(in: currentContext)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    static func fetchImage(from url: URL, completion: @escaping (UIImage?, Error?) -> ()) {
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
        if let response = URLCache.shared.cachedResponse(for: request) {
            if let image = UIImage(data: response.data) {
                completion(image, nil)
            }
        } else {
            let session = URLSession(configuration: .cached)
            let dataTask = session.dataTask(with: request) { (data, response, error) in
                if let err = error {
                    completion(nil, err)
                } else {
                    if (response as? HTTPURLResponse) != nil {
                        if let imageData = data, let image = UIImage(data: imageData) {
                            completion(image, nil)
                        } else {
                            print("Image file is corrupted")
                        }
                    } else {
                        print("No response from server")
                    }
                }
                if data != nil && response != nil {
                    let cachedResponse = CachedURLResponse(response: response!, data: data!)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                }
            }
            dataTask.resume()
        }
    }
    
    static func createBoldAttributedString(string: String, fontSize: CGFloat) -> NSMutableAttributedString {
        return NSMutableAttributedString(
            string: string,
            attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: fontSize)]
        )
    }
}

extension URLSessionConfiguration {
    open class var `cached`: URLSessionConfiguration {
        let mb = 1024 * 1024 * 10
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 100 * mb, diskCapacity: 100 * mb, diskPath: "images")
        return configuration
    }
}

extension Date {
    var longString: String {
        return makeString(dateFormat: "EEE MMM dd, HH:mm")
    }
    
    var shortString: String {
        return makeString(dateFormat: "MMM dd, yyyy")
    }
    
    private func makeString(dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: self)
    }
}

extension String {
    func convertToLongDate() -> Date? {
        return convertToDate(dateFormat: "EEE MMM dd, HH:mm")
    }
    
    func convertToShortDate() -> Date? {
        return convertToDate(dateFormat: "MMM dd, yyyy")
    }
    
    private func convertToDate(dateFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.date(from: self)
    }
}


