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

struct Vector3 {
    var x: Float
    var y: Float
    var z: Float
}

public class GameObject{
    public var name: String // must be defined
    public var tag: String? // can be nil
    var ObjectVertexData: [GLfloat]
    var position: Vector3 = Vector3(x: 0, y: 0, z: 0)
    var scale: Float
    var baseMatrix: GLKMatrix4
    
    
    //Initialize object fields
    init(name: String, tag: String?, ObjectVertexData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.ObjectVertexData = ObjectVertexData
        self.position.x = xPos
        self.position.y = yPos
        self.position.z = zPos
        self.scale = scale
        self.baseMatrix = baseMatrix
    }
    
    //combine seperated vertex and normal array into a single array for drawing
    func combineVerticesAndNormals(vertexData: [GLfloat], normalData: [GLfloat]){
        
    }
    
    //overloaded init for seperated vertices and normals from blender
    init(name: String, tag: String?, ObjectVertexData: [GLfloat], ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
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
        self.position.x = xPos;
        self.position.y = yPos;
        self.position.z = zPos;
        self.scale = scale
        self.baseMatrix = baseMatrix
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
        return GLKMatrix4MakeTranslation(
            self.position.x,
            self.position.y,
            self.position.z
        );
    }
    
    //Move the object by the passed amount in each dimension
    func moveObject(xMove: Float, yMove: Float, zMove: Float){
        self.position.x += xMove;
        self.position.y += yMove;
        self.position.z += zMove;
    }
}
