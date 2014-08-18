//
//  ParseHelper.swift
//  ManhattanForum
//
//  Created by Dimitri Roche on 8/18/14.
//  Copyright (c) 2014 dimroc. All rights reserved.
//

import Foundation

class ParseHelper {
    class func launch(launchOptions: NSDictionary?) {
        Parse.setApplicationId(
            Credentials.objectForKey("ParseApplicationId"),
            clientKey: Credentials.objectForKey("ParseClientKey"))
        
        PFFacebookUtils.initializeFacebook()
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
    }
}