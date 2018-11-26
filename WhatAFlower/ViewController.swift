//
//  ViewController.swift
//  WhatAFlower
//
//  Created by Filip on 26/11/2018.
//  Copyright © 2018 Filip. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
        
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            //imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError()
            }
            
            detect(flowerImage: ciimage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    @IBAction func camerTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError()
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError()
            }
            
            
            
            self.navigationItem.title = classification.identifier.capitalized
            
            self.getFlowerUrl(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            
            try handler.perform([request])
            
        } catch {
            
            print(error)
            
        }
        
    }
    
    
    func getFlowerUrl(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON
            { response in
                
                if response.result.isSuccess {
                    
                    print("Success!")
                    
                    let flowerJSON: JSON = JSON(response.result.value!)
                    let pageID = flowerJSON["query"]["pageids"][0].stringValue
                    let flowerDescritpion = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                    let flowerImageUrl = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                    self.imageView.sd_setImage(with: URL(string: flowerImageUrl))
                    self.label.text = flowerDescritpion
                    
                } else {
                    print("Error \(response.result.error!)")
                    self.label.text = "Connection Issues"
                    
                    
                }
                
        }
        
    }
    
    
}
