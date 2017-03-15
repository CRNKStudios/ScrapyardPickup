//
//  PlayerObject.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-03-13.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import GLKit

public class PlayerObject: GameObject {
    override init(name: String, tag: String?, objectData: [Vertex], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        super.init(name: name, tag: tag, objectData: objectData, xPos, yPos, zPos, scale: scale, baseMatrix: baseMatrix)
        self.tag = "Player"
    }
}
