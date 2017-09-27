//
//  ProfilePictureTaker.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

import MobileCoreServices

protocol ProfilePictureTakerDelegate : class {
    func showImagePickerController(picker: UIImagePickerController)
    func showChooserAlert(alert: UIAlertController)
    func imagePicked(image: UIImage, picker: UIImagePickerController)
    func cancelPicker(picker: UIImagePickerController)
    func deleteImage()
    func gotoSystemSettins(type: NSInteger)
}


class ProfilePictureTaker : NSObject {
    
    weak var delegate: ProfilePictureTakerDelegate?
    
    init(delegate: ProfilePictureTakerDelegate) {
        self.delegate = delegate
    }
    
    var imagePicker = UIImagePickerController()
    let baseTool = TDBaseToolModel()
    
    func start(alreadyHasImage: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let action = UIAlertAction(title: Strings.Profile.takePicture, style: .Default) { _ in
                self.showImagePicker(.Camera)
            }
            alert.addAction(action)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let action = UIAlertAction(title: Strings.Profile.chooseExisting, style: .Default) { _ in
                self.showImagePicker(.PhotoLibrary)
            }
            alert.addAction(action)
        }
        if alreadyHasImage {
            let action = UIAlertAction(title: Strings.Profile.removeImage, style: .Destructive) { _ in
                self.delegate?.deleteImage()
            }
            alert.addAction(action)
        }
        alert.addCancelAction()
        delegate?.showChooserAlert(alert)
    }
    
 
    private func showImagePicker(sourceType : UIImagePickerControllerSourceType) {
        
        let isAuthen : Bool = self.baseTool.judgeCameraOrAlbumUserAllow(sourceType == .PhotoLibrary ? 0 :1)
        if isAuthen != true {
            self.delegate?.gotoSystemSettins(sourceType == .PhotoLibrary ? 0 :1)
            return
        }
        
        let mediaType: String = kUTTypeImage as String
        imagePicker.mediaTypes = [mediaType]
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        
        if sourceType == .Camera {
            imagePicker.showsCameraControls = true
            imagePicker.cameraCaptureMode = .Photo
            imagePicker.cameraDevice = .Front
            imagePicker.cameraFlashMode = .Auto
        }
        self.delegate?.showImagePickerController(imagePicker)
    }
}


extension ProfilePictureTaker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            let rotatedImage = image.rotateUp()
//            let cropper = CropViewController(image: rotatedImage) { [weak self] maybeImage in
//                if let newImage = maybeImage {
//                    self?.delegate?.imagePicked(newImage, picker: picker)
//                } else {
//                    self?.delegate?.cancelPicker(picker)
//                }
//            }
//            picker.pushViewController(cropper, animated: true)
//        } else {
//            fatalError("no image returned from picker")
//        }
        
        //        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
        //            self.delegate?.imagePicked(image, picker: picker)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let omageHeight = image.size.height * (TDScreenWidth / image.size.width);
            let orImage : UIImage = image.resizeImageWithSize(CGSizeMake(TDScreenWidth, omageHeight))
            let cutViewController = TDCutImageViewController.init(image: orImage, delegate: self)
            cutViewController.ovalClip = true
            cutViewController.cancelHandle = { (AnyObject) -> () in
                self.delegate?.cancelPicker(picker)
            }
            picker.pushViewController(cutViewController, animated: true)
            
        } else {
            fatalError("no image returned from picker")
        }
    }
    
    func cropImageDidFinishedWithImage(image : UIImage) {
        self.delegate?.imagePicked(image, picker: self.imagePicker)
    }
    
}
