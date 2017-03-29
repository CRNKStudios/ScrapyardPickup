//
//  PlayerObject.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-03-13.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import GLKit

/**
    PlayerObject Class
    
    Create a player object that sets the string to be "Player" only. Should be
    called max = 1 in a game setup. (Only 1 player in our game).
 */
public class PlayerObject: GameObject {
    override init() {
        super.init()
        self.tag = "Player"
    }
    override init(name: String, tag: String?, vertexArray: GLuint, vertexBuffer: GLuint, objectData: VertexData, _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        super.init(name: name, tag: tag, vertexArray: vertexArray, vertexBuffer: vertexBuffer, objectData: objectData, xPos, yPos, zPos, scale: scale, baseMatrix: baseMatrix)
        self.tag = "Player"
    }
}
