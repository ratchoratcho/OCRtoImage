//
//  OCRService.swift
//  MYJanken
//
//  Created by 杉浦光紀 on 2019/01/30.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import TesseractOCR

protocol OCRServiceDelegate: class {
    func ocrService(_ service: OCRService, didDetects texts: [String])
}

class OCRService {
    
    private let tesseract = G8Tesseract(language: "jpn+eng")!


    weak var delegate: OCRServiceDelegate?
    
    init() {
        tesseract.engineMode = .tesseractOnly
        tesseract.pageSegmentationMode = .singleBlock
    }

    
    func handle(images: [UIImage]) {
        handleWithTesseract(images: images)
    }
    private func handleWithTesseract(images: [UIImage]) {
//        tesseract.image = image.g8_blackAndWhite()
//        tesseract.image = image
//        tesseract.recognize()
//        let text = tesseract.recognizedText ?? ""
//        print(text)
//        delegate?.ocrService(self, didDetect: text)
        var detectedTexts: [String] = []
        images.forEach({image in
            tesseract.image = image.g8_grayScale()
            tesseract.recognize()
            let text = tesseract.recognizedText ?? ""
            print(text)
            detectedTexts.append(text)
        })
        delegate?.ocrService(self, didDetects: detectedTexts)
    }
    
}
