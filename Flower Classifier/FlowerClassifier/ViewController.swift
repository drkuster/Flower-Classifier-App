//
//  ViewController.swift
//  FlowerClassifier
//
//  Created by Dylan Kuster on 5/14/20.
//  Copyright © 2020 Dylan Kuster. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    
    private let cameraController = UIImagePickerController()
    private let libraryController = UIImagePickerController()
    private let baseURL = "https://en.wikipedia.org/w/api.php?"
    @IBOutlet weak var flowerImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var getStartedLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        cameraController.delegate = self
        cameraController.allowsEditing = true
        cameraController.sourceType = .camera // CHANGE TO CAMERA LATER
        libraryController.delegate = self
        libraryController.allowsEditing = true
        libraryController.sourceType = .photoLibrary
        flowerImageView.isHidden = true
        descriptionLabel.isHidden = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let imageSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        else
        {
            fatalError("Could not convert to UIImage")
        }
        
        guard let imageAsCI = CIImage(image: imageSelected)
        else
        {
            fatalError("Could not convert to CIImage")
        }
        flowerImageView.image = imageSelected
        analyzeImage(image : imageAsCI)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func analyzeImage(image : CIImage)
    {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)
        else
        {
            fatalError("Could not convert to VNCoreModel")
        }
        
        let request = VNCoreMLRequest(model: model)
        { (request, error) in
            if error == nil
            {
                guard let results = request.results as? [VNClassificationObservation]
                else
                {
                    fatalError("Could not cast to array of VNClassificationObjects")
                }
                
                if let bestResult = results.first?.identifier
                {
                    self.updateWithResults(result : bestResult)
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage : image)
        do
        {
            try handler.perform([request])
        }
        
        catch let error
        {
            print(error)
        }
    }
    
    func updateWithResults(result : String)
    {
        self.title = result.capitalized
        let parameters : [String : String] =
        [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
            "titles" : result
        ]
        
        AF.request(baseURL, method: .get, parameters: parameters).responseJSON
        { (response) in
            if let data = response.data
            {
                guard let jsonResponse = try? JSON(data: data)
                else
                {
                    fatalError("Could not convert to JSON")
                }
                let pageID = jsonResponse["query"]["pageids"][0].stringValue
                print(pageID)
                self.descriptionLabel.text = jsonResponse["query"]["pages"][pageID]["extract"].stringValue
                self.descriptionLabel.isHidden = false
                self.flowerImageView.isHidden = false
                self.getStartedLabel.isHidden = true
            }
        }
        
    }
    
    @IBAction func addToLibraryPressed(_ sender: UIBarButtonItem)
    {
        present(libraryController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem)
    {
        present(cameraController, animated: true, completion: nil)
    }
    
}

