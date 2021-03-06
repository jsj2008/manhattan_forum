//
//  LocationManager.swift
//  ManhattanForum
//
//  Created by Dimitri Roche on 8/27/14.
//  Copyright (c) 2014 dimroc. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager? = nil
    var completionSource: BFTaskCompletionSource = BFTaskCompletionSource()
    
    func startAsync() -> BFTask {
        self.locationManager = LocationManager.generateCLLocationManager(self)
        return completionSource.task
    }
    
    private class func generateCLLocationManager(locationManagerInstance: LocationManager) -> CLLocationManager! {
        var cllocationManager = CLLocationManager()
        cllocationManager.delegate = locationManagerInstance
        cllocationManager.distanceFilter = kCLDistanceFilterNone
        cllocationManager.desiredAccuracy = kCLLocationAccuracyBest
        cllocationManager.requestWhenInUseAuthorization()
        cllocationManager.startUpdatingLocation()
        return cllocationManager
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        DDLogHelper.debug("didChangeAuthorizationStatus: \(status.rawValue)")
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        DDLogHelper.debug("## INFO: Updating location!")
        let location: CLLocation = locations.last! as CLLocation
        DDLogHelper.debug(location.description)
        locationManager!.stopUpdatingLocation()

        // The location manager can invoke this delegate method multiple times
        // before stopUpdatingLocation() takes effect.
        // This is why we invoke completionsource.trySet... at the end of each delegate.
        if (CLLocationCoordinate2DIsValid(location.coordinate)) {
            googleGeocode(location)
        } else {
            locationCoordinate2DIsInValid()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        DDLogHelper.debug("Encountered an error retrieving location: \(error.code) - \(error.description)")
        locationManager!.stopUpdatingLocation()
        self.completionSource.trySetError(error)
    }
    
    private func locationCoordinate2DIsInValid() {
        let details = [NSLocalizedDescriptionKey: "Unable to retrieve a valid coordinate."]
        let error = NSError(domain: "locationmanager.locationCoordinate2DIsValid.google.manhattanforum.com", code: 0, userInfo: details)
        self.completionSource.trySetError(error)
    }
    
    private func googleGeocode(cllocation: CLLocation!) {
        DDLogHelper.debug("Retrieving reverse geocode for \(cllocation.description)")
        GoogleGeocoder.reverse(cllocation.coordinate).continueWithBlock { (task: BFTask!) -> AnyObject! in
            if(task.success) {
                let location = task.result as MFLocation!
                self.googleGeocodeSuccess(location)
            } else {
                self.googleGeocodeError(task.error)
            }
            
            return nil
        }
    }

    private func googleGeocodeSuccess(location: MFLocation!) {
        DDLogHelper.debug(location.description)
        if (location.valid) {
            self.completionSource.trySetResult(location)
        } else {
            let details = [NSLocalizedDescriptionKey: "Unable to find a valid location with neighborhood, sublocality, and locality."]
            let error = NSError(domain: "locationmanager.geocode.google.manhattanforum.com", code: 0, userInfo: details)
            self.completionSource.trySetError(error)
        }
    }

    private func googleGeocodeError(error: NSError) {
        DDLogHelper.debug(error.description)
        self.completionSource.trySetError(error)
    }
}