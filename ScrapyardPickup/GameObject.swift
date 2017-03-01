//
//  GameObject.swift
//  ScrapyardPickup
//
//  Created by robert moffat on 2/28/17.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//
//  Base GameObject class to be extended by the different game classes.

import Foundation
import OpenGLES
import GLKit

class GameObject{
    var ObjectVertexData: [GLfloat];
    var xPos: Float = 0.0;
    var yPos: Float = 0.0;
    var zPos: Float = 0.0;
    
    //Initialize object fields
    init(ObjectVertexData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float){
        self.ObjectVertexData = ObjectVertexData;
        self.xPos = xPos;
        self.yPos = yPos;
        self.zPos = zPos;
    }
    
    //combine seperated vertex and normal array into a single array for drawing
    func combineVerticesAndNormals(vertexData: [GLfloat], normalData: [GLfloat]){
        
    }
    
    //overloaded init for seperated vertices and normals from blender
    init(ObjectVertexData: [GLfloat], ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float){
        self.xPos = xPos;
        self.yPos = yPos;
        self.zPos = zPos;
        self.ObjectVertexData = [GLfloat]();
        var j = 0;
        var k = 0;
        for index in 0...ObjectVertexData.count + ObjectNormalData.count - 1{
            if(index % 6 < 3){
                self.ObjectVertexData.append(ObjectVertexData[j]);
                j += 1;
            }
            if(index % 6 >= 3){
                self.ObjectVertexData.append(ObjectNormalData[k]);
                k += 1;
            }
        }
    }
    
    //Deinitialize game object
    deinit {
        print("Object deinitialized");
    }
    
    //Returns the object's vertex data
    func getObjectVertexData() -> [GLfloat]{
        return ObjectVertexData;
    }
    
    //Get objects translation matrix for drawing
    func getTranslationMatrix() -> GLKMatrix4{
        return GLKMatrix4MakeTranslation(xPos, yPos, zPos);
    }
    
    //Move the object by the passed amount in each dimension
    func moveObject(xMove: Float, yMove: Float, zMove: Float){
        xPos+=xMove;
        yPos+=yMove;
        zPos+=zMove;
    }
}
