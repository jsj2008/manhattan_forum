//
//  CreateTopicViewController.swift
//  ManhattanForum
//
//  Created by Dimitri Roche on 8/21/14.
//  Copyright (c) 2014 dimroc. All rights reserved.
//

import UIKit
import MobileCoreServices

class CreateTopicViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textPlaceHolder: UILabel!
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    var locationManager: LocationManager? = nil
    
    override func viewDidLoad() {
        textView.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.postButton.enabled = false;
        
        // Must hold on to ivar in memory otherwise ARC GC will clean up instance prematurely and stop prompting for user location
        self.locationManager = LocationManager.start({ (response) -> Void in
            switch response {
            case .Error(let error):
                NSLog(error.description)
                self.presentViewController(
                    UIAlertControllerFactory.ok("Error with Location", message: "Unable to get neighborhood!\nPlease close post and try again later."),
                    animated: true,
                    completion: { () -> Void in }
                )
            case .Response(let location):
                self.textPlaceHolder.text = "Share \(location.description)"
                self.postButton.enabled = true;
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        println("Removing location manager")
        locationManager = nil
    }
    
    @IBAction func postTopic(sender: AnyObject) {
        NSLog("Posting...")
    }
    
    @IBAction func showCameraActionSheet(AnyObject) {
        var alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            println("Canceled camera action.")
        }
        
        var takePhotoAction = UIAlertAction(title: "Take photo", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.showPhotoCamera()
        }
        
        var takeVideoAction = UIAlertAction(title: "Take video", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.showVideoCamera()
        }
        
        var chooseFromLibraryAction = UIAlertAction(title: "Choose from Library", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.showImagePicker(UIImagePickerControllerSourceType.SavedPhotosAlbum)
        }
        
        alertController.addAction(takePhotoAction)
        alertController.addAction(takeVideoAction)
        alertController.addAction(chooseFromLibraryAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true) { () -> Void in
        }
    }
    
    private func showVideoCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            let picker = UIImagePickerController()
            picker.delegate = self;
            picker.allowsEditing = true;
            picker.videoMaximumDuration = 15.0;
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.mediaTypes = [kUTTypeMovie]
            presentViewController(picker, animated: true) { () -> Void in
            }
        } else {
            self.presentViewController(UIAlertControllerFactory.ok("No Camera", message: "No Camera Available"), animated: true, completion: { () -> Void in
            })
        }
    }
    
    private func showPhotoCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            showImagePicker(UIImagePickerControllerSourceType.Camera)
        } else {
            self.presentViewController(UIAlertControllerFactory.ok("No Camera", message: "No Camera Available"), animated: true, completion: { () -> Void in
            })
        }
    }
    
    private func showImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self;
        picker.sourceType = sourceType
        presentViewController(picker, animated: true) { () -> Void in
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
        var chosenImage = info[UIImagePickerControllerEditedImage] as? UIImage
        if(chosenImage == nil) {
            chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        imageView.image = chosenImage
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
        })
    }
}