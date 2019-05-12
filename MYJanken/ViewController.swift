//
//  ViewController.swift
//  MYJanken
//
//  Created by 杉浦光紀 on 2019/01/30.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import UIKit
import ARKit
import Vision
import TesseractOCR
import SwiftyJSON

class ViewController: UIViewController, UIGestureRecognizerDelegate, ARSCNViewDelegate, ARSessionDelegate {

    
    
    @IBAction func shutterButton(_ sender: Any) {
//        testFunc()
        gcpTestFunc()
    }
    @IBOutlet weak var detectMessage: UITextView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    let pasteboard: UIPasteboard = UIPasteboard.general
    
    private let boxService = BoxService()
    private let ocrService = OCRService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        boxService.delegate = self
        ocrService.delegate = self
        detectMessage.sizeToFit()
        
        // キーボードを閉じる奴の設定
        let toolBar = UIToolbar()
        toolBar.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        toolBar.sizeToFit()
        let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(ViewController.doneButton))
        toolBar.items = [space,doneButton]
        detectMessage.inputAccessoryView = toolBar
        pasteboard.string = "トマト"
    }

    //doneボタンを押した時の処理
    @objc func doneButton(){
        //キーボードを閉じる
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTapGestureToSceneView()
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        guard let node = hitTestResults.first?.node else {
            let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
            if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
                let translation = hitTestResultWithFeaturePoints.worldTransform.translation
//                testFunc()
                print(pasteboard.string)
                if let searchKey = pasteboard.string {
                    getImage(query: searchKey, x: translation.x, y: translation.y, z: translation.z)
                }
            }
            return
        }
        node.removeFromParentNode()
    }
    
    var count: Int = 0
    
    func getImage(query: String, x: Float, y: Float, z: Float) {
        let apiKey: String = "my secret api key"
        let cx: String = "my secret cx"
        var urlComponents = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        urlComponents.queryItems = [
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: cx)
        ]
        print(urlComponents.string!)
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!) {
            data, response, error in
            guard let jsonData = data else {
                print(error as Any)
                return
            }
            do {
                let result = try JSONDecoder().decode(CustomSearchedResult.self, from: jsonData)
                print(result.items[0])
                let task = URLSession.shared.dataTask(with: result.items[self.count].link) {data, response, error in
                    guard let image = data.flatMap(UIImage.init) else {
                        print(error as Any)
                        return
                    }
                    // imageとれた
                    let planeNode = NodeAdder.createImageNode(sceneView: self.sceneView, image: image, x: x, y: y, z: z)
                    self.sceneView.scene.rootNode.addChildNode(planeNode)
                    self.count += 1
                }
                task.resume()
            } catch(let e) {
                print(e)
            }
        }
        task.resume()
    }
    
    // Structure defined by https://developers.google.com/custom-search/json-api/v1/reference/cse/list#response
    struct CustomSearchedResult: Codable {
        struct Item: Codable {
            struct Image: Codable {
                let contextLink: String
                let thumbnailLink: String
                let thumbnailHeight: Int
                let thumbnailWidth: Int
            }
            let link: URL
            let displayLink: URL
            let mime: String
            let image: Image
        }
        let items: [Item]
    }
    
    func testFunc() {
        detectMessage.text = ""
        let buf = self.currentBuffer
        let ciImage = CIImage(cvPixelBuffer: buf!)
        guard let image = ciImage.toUIImage() else {
            return
        }
        let image2 = image.rotatedBy(degree: 90)
        
        makeRequest(image: image2)
    }
    
    func gcpTestFunc() {
        detectMessage.text = ""
        let buf = self.currentBuffer
        let ciImage = CIImage(cvPixelBuffer: buf!)
        guard let image = ciImage.toUIImage() else {
            return
        }
        let image2 = image.rotatedBy(degree: 90)
        let binaryImageData = base64EncodeImage(image2)
        defer {
            currentBuffer = nil
        }
        createRequest(with: binaryImageData)
    }
    
    // MARK: - ARSessionDelegate
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    /// - Tag: ConsumeARFrames
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
//        print(type(of: frame))
//        print(type(of: frame.capturedImage))
//
//        let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
//        guard let image = ciImage.toUIImage() else {
//            return
//        }
//        let image2 = image.rotatedBy(degree: 90)
//        makeRequest(image: image2)
    }
    
    func makeRequest(image: UIImage) {
        guard let cgImage = image.cgImage else {
            assertionFailure()
            return
        }
        
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation.up,
            options: [VNImageOption: Any]()
        )
        let request = VNDetectTextRectanglesRequest(completionHandler: { [weak self] request, error in
            DispatchQueue.main.async {
                self?.handle(image: image, request: request, error: error)
            }
        })
        
        request.reportCharacterBoxes = true
        do {
            // Release the pixel buffer when done, allowing the next buffer to be processed.
            defer { self.currentBuffer = nil }
            try handler.perform([request])
        } catch {
            print(error as Any)
        }
    }
    private func handle(image: UIImage, request: VNRequest, error: Error?) {
        guard
            let results = request.results as? [VNTextObservation]
            else {
                return
        }
        print(results)
        print("boxServiceの前")
        let overlayLayer = CALayer()
        boxService.handle(
            overlayLayer: overlayLayer,
            image: image,
            results: results,
            on: sceneView
        )
    }
    
    
    
    ///////////////////////////GCPVision///////////////////////
    var googleAPIKey = "AIzaSyCU9kiCShsOjBY1r3ZZFWvfrh1bGR5iTP8"
    let session = URLSession.shared
    
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = image.pngData()
        
        // Resize the image if it exceeds the 2MB API limit
        if ((imagedata?.count)! > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    func createRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "TEXT_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        //        let jsonObject = JSON(jsonDictionary: jsonRequest)
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            print("this is data")
            print(data)
            print("this is response")
            print(response)
            self.analyzeResults(data)
        }
        
        task.resume()
    }
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                //                self.labelResults.text = "Error code \(errorObj["code"]): \(errorObj["message"])"
                print("error")
            } else {
                // Parse the response
                print(json)
                let responses: JSON = json["responses"][0]
                
                // Get label annotations
                let labelAnnotations: JSON = responses["textAnnotations"]
                let numLabels: Int = labelAnnotations.count
                var labels: Array<String> = []
                print(labels)
                if numLabels > 0 {
                    var labelResultsText:String = "Labels found: "
                    for index in 0..<numLabels {
                        let label = labelAnnotations[index]["description"].stringValue
                        labels.append(label)
                    }
                    for label in labels {
                        // if it's not the last item add a comma
                        if labels[labels.count - 1] != label {
                            labelResultsText += "\(label), "
                        } else {
                            labelResultsText += "\(label)"
                        }
                    }
                    //                    self.labelResults.text = labelResultsText
                    print(labelResultsText)
                    self.detectMessage.text = labelResultsText
                } else {
                    print("no text detected")
                }
            }
        })
    }
}

extension ViewController: BoxServiceDelegate {
    func boxService(_ service: BoxService, didDetect images: [UIImage]) {
        print("boxServiceのDelegate")
        ocrService.handle(images: images)
    }
}

extension ViewController: OCRServiceDelegate {
    func ocrService(_ service: OCRService, didDetects texts: [String]) {
        print(texts)
        texts.forEach({text in
            print(text)
            detectMessage.text += text
        })
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
