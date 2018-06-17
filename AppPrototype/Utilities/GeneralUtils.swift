//
//  GeneralUtils.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/3/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
    open class var `cached`: URLSessionConfiguration {
        let mb = 1024 * 1024 * 10
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 100 * mb, diskCapacity: 100 * mb, diskPath: "images")
        return configuration
    }
}
