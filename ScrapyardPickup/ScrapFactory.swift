//
//  ModelFactory.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-03-28.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import GLKit

public enum SCRAPMODELSTRING: String {
    case    SCRAP_BOX   = "scrap_box"
    case    SCRAP_FRAME = "scrap_frame"
    case    SCRAP_BAR   = "scrap_bar"
    case    SCRAP_CAR   = "scrap_car"
}

public enum SCRAPMODEL: Int {
    case    SCRAP_BOX
    case    SCRAP_FRAME
    case    SCRAP_BAR
    case    SCRAP_CAR

    static let count: UInt32 = 4
    static func randomModel() -> SCRAPMODEL {
        // pick and return a new value
        let rand = arc4random_uniform(count)
        return SCRAPMODEL(rawValue: Int(rand))!
    }
}

class ScrapFactory {
    init() {
        
    }
    
    public static func generateScrapObjects(level: Int) -> [GameObject] {
        var objects: [GameObject] = []
        //Generate objects based on levels
        for i in 0..<(level * Int((arc4random_uniform(2)) + 1 * 3)) {
            //Generate random positions within bounds
            var xPos: Float = Float(arc4random_uniform(UInt32(5))) - Float(2);
            var yPos: Float = Float(0.0);
            var zPos: Float = (Float(arc4random_uniform(UInt32(10)))) * Float(-1);
            //If object spawn on top of the grinder, move it away
            if(zPos == 0 && xPos <= -1){
                xPos += 1;
            }
            
            switch SCRAPMODEL.randomModel() {
                case .SCRAP_BOX:
                    objects.append(
                        GameObject(
                            name: SCRAPMODELSTRING.SCRAP_BOX.rawValue + String(i),
                            tag: "Scrap",
                            vertexArray: 0,
                            vertexBuffer: 0,
                            objectData: ModelObject.parseOBJFileToModel(fileName: SCRAPMODELSTRING.SCRAP_BOX.rawValue).getModelData(),
                            xPos,
                            yPos,
                            zPos,
                            scale: 1.0,
                            baseMatrix: GLKMatrix4Identity
                        )
                    )
                    break
                case .SCRAP_FRAME:
                    objects.append(
                        GameObject(
                            name: SCRAPMODELSTRING.SCRAP_FRAME.rawValue + String(i),
                            tag: "Scrap",
                            vertexArray: 0,
                            vertexBuffer: 0,
                            objectData: ModelObject.parseOBJFileToModel(fileName: SCRAPMODELSTRING.SCRAP_FRAME.rawValue).getModelData(),
                            xPos,
                            yPos,
                            zPos,
                            scale: 1.0,
                            baseMatrix: GLKMatrix4Identity
                        )
                    )
                    break
                case .SCRAP_BAR:
                    objects.append(
                        GameObject(
                            name: SCRAPMODELSTRING.SCRAP_BAR.rawValue + String(i),
                            tag: "Scrap",
                            vertexArray: 0,
                            vertexBuffer: 0,
                            objectData: ModelObject.parseOBJFileToModel(fileName: SCRAPMODELSTRING.SCRAP_BOX.rawValue).getModelData(),
                            xPos,
                            yPos,
                            zPos,
                            scale: 1.0,
                            baseMatrix: GLKMatrix4Identity
                        )
                    )
                    break
                case .SCRAP_CAR:
                    objects.append(
                        GameObject(
                            name: SCRAPMODELSTRING.SCRAP_CAR.rawValue + String(i),
                            tag: "Scrap",
                            vertexArray: 0,
                            vertexBuffer: 0,
                            objectData: ModelObject.parseOBJFileToModel(fileName: SCRAPMODELSTRING.SCRAP_CAR.rawValue).getModelData(),
                            xPos,
                            yPos,
                            zPos,
                            scale: 1.0,
                            baseMatrix: GLKMatrix4Identity
                        )
                    )
                    break
                // no default
            }
        }
        return objects
    }
}
