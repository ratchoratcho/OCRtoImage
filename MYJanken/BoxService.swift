//
//  BoxService.swift
//  MYJanken
//
//  Created by 杉浦光紀 on 2019/01/30.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import UIKit
import Vision

protocol BoxServiceDelegate: class {
    func boxService(_ service: BoxService, didDetect images: [UIImage])
}


class BoxService {
    weak var delegate: BoxServiceDelegate?
    
    func handle(
        overlayLayer: CALayer,
        image: UIImage, results: [VNTextObservation], on view: UIView) {
        
        overlayLayer.sublayers?.forEach({ (layer) in
            layer.removeFromSuperlayer()
        })
        
        let results = results.filter({ $0.confidence > 0.7 })
        
//        // box
//        results.forEach({ result in
//            let normalisedRect = normalise(box: result)
//            drawBox(overlayLayer: overlayLayer, normalisedRect: normalisedRect)
//        })
        
//        // image
//        guard let biggestResult = results
//            .sorted(by: { $0.boundingBox.width > $1.boundingBox.width })
//            .first else {
//                return
//        }
        
//        let normalisedRect = normalise(box: biggestResult)
//        if let croppedImage = cropImage(image: image, normalisedRect: normalisedRect) {
//            delegate?.boxService(self, didDetect: croppedImage)
//        }
        myFunc(results: results, image: image)
    }
    
    private func myFunc(results: [VNTextObservation], image: UIImage) {
        var croppedImages: [UIImage] = []
        results.forEach({result in
            let normalisedRect = normalise(box: result)
            if let croppedImage = cropImage(image: image, normalisedRect: normalisedRect) {
                croppedImages.append(croppedImage)
            }
        })
        delegate?.boxService(self, didDetect: croppedImages)
    }
    
    private func cropImage(image: UIImage, normalisedRect: CGRect) -> UIImage? {
        let x = normalisedRect.origin.x * image.size.width
        let y = normalisedRect.origin.y * image.size.height
        let width = normalisedRect.width * image.size.width
        let height = normalisedRect.height * image.size.height
        
        let rect = CGRect(x: x, y: y, width: width, height: height).scaleUp(scaleUp: 0.1)
        
        guard let cropped = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
        print("cropしてます")
        print(type(of: croppedImage))
        return croppedImage
    }
    
    private func drawBox(overlayLayer: CALayer, normalisedRect: CGRect) {
        let x = normalisedRect.origin.x * overlayLayer.frame.size.width
        let y = normalisedRect.origin.y * overlayLayer.frame.size.height
        let width = normalisedRect.width * overlayLayer.frame.size.width
        let height = normalisedRect.height * overlayLayer.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: x, y: y, width: width, height: height).scaleUp(scaleUp: 0.1)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        overlayLayer.addSublayer(outline)
    }
    
    private func normalise(box: VNTextObservation) -> CGRect {
        return CGRect(
            x: box.boundingBox.origin.x,
            y: 1 - box.boundingBox.origin.y - box.boundingBox.height,
            width: box.boundingBox.size.width,
            height: box.boundingBox.size.height
        )
    }
    
}

extension CGRect {
    func scaleUp(scaleUp: CGFloat) -> CGRect {
        let biggerRect = self.insetBy(
            dx: -self.size.width * scaleUp,
            dy: -self.size.height * scaleUp
        )
        
        return biggerRect
    }
}
