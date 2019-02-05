//
//  NodeAdder.swift
//  MyAR
//
//  Created by 杉浦光紀 on 2019/01/23.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//
import UIKit
import ARKit

class NodeAdder: UIView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    static func createTextNode(sceneView: SCNView,text: String, x: Float, y: Float, z: Float) -> SCNNode {
        print("add text node to scene")
        let text = SCNText(string: text, extrusionDepth: 0)
        text.font = UIFont(name: "HiraKakuProN-W6", size: 0.2)
        text.firstMaterial?.diffuse.contents = UIColor.blue
        let textNode = SCNNode(geometry: text)
        let (min, max) = (text.boundingBox)
        let deltaX = CGFloat(max.x - min.x)
        textNode.opacity = 0.9
        let fromCamera = SCNVector3(-deltaX/2, -1, -2)
        if let camera = sceneView.pointOfView {
            textNode.position = camera.convertPosition(fromCamera, to: nil)
            textNode.eulerAngles = camera.eulerAngles
        }
        return textNode
    }
    
    static func createImageNode(sceneView: SCNView, image: UIImage, x: Float, y: Float, z: Float) -> SCNNode {
        let plane = SCNPlane(width: 0.15, height: 0.15)
        let planeNode = SCNNode(geometry: plane)
        let materialFront = SCNMaterial()
        materialFront.diffuse.contents = image
        planeNode.geometry?.materials = [materialFront]
        planeNode.position = SCNVector3(x: x, y: y, z: z)
        if let camera = sceneView.pointOfView {
            planeNode.eulerAngles = camera.eulerAngles
        }
        return planeNode
    }
    
}
