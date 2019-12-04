//
//  ViewController.swift
//  ML-Blog
//
//  Created by Daniel Radshun on 02/12/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var model:PetClassifier!
    var pickedImage:UIImage?
    
    var imagePicker: UIImagePickerController!
    
    var videoPreview = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var takePhotoPressed: UIButton!
    @IBAction func takePhotoPressed(_ sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    //car price ML
    var carPricerModel:CarPricer!
    
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var engineTextField: UITextField!
    @IBOutlet weak var kmTextField: UITextField!
    @IBAction func calculatePressed(_ sender: UIButton) {
        if yearTextField.text != "" &&
            engineTextField.text != "" &&
            kmTextField.text != ""{
            
            determineCarPrice(car: Car(carYear: Double(yearTextField.text!)!, engine: Double(engineTextField.text!)!, destinationPassed: Double(kmTextField.text!)!))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        model = PetClassifier()
        carPricerModel = CarPricer()
    }

    private func convertImageTo299X299Dimensions(image:UIImage) -> CVPixelBuffer?{
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
    
    func checkIfRecognized(pixelBuffer:CVPixelBuffer){
        guard let prediction = try? model.prediction(image: pixelBuffer) else {
            return
        }
        resultLabel.text = "There is \(prediction.classLabel) in the photo"
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let cameraImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        pickedImage = cameraImage
        imageView.image = cameraImage
        
        let pixelBuffer = convertImageTo299X299Dimensions(image: cameraImage!)
        checkIfRecognized(pixelBuffer: pixelBuffer!)
    }
}

extension ViewController{
    
    func determineCarPrice(car:Car){
        guard let prediction = try? carPricerModel.prediction(Car_Year: car.carYear, Engine: car.engine, Destination_Passed: car.destinationPassed) else {
            return
        }
        resultLabel.text = "The car's estimated price is \(Int(prediction.Price))"
    }
}
