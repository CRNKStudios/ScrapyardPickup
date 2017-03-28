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

/**
    Vertex Structure
    
    As discussed, each point drawn to the screen has a: position, texture and 
    normal (in that order read from `faces` in an `*.obj` file).
 */
public struct VertexData {
    var position: [GLfloat]
    var texture: [GLfloat]
    var normal: [GLfloat]
}

/**
    GameObject Class
 
    All objects (models) in the game are of the class `GameObject`. Anything 
    that all objects should have should be put in here for quick access and easy
    reading.
 */
public class GameObject{
    public var name: String // must be defined
    public var tag: String? // can be nil
    var objectData: VertexData
    var position: GLKVector4 = GLKVector4Make(0.0, 0.0, 0.0, 0.0)
    var scale: Float
    var baseMatrix: GLKMatrix4
    
    init() {
        self.name = ""
        self.tag = ""
        self.objectData = VertexData(position: [], texture: [], normal: [])
        self.position = GLKVector4Make(0, 0, 0, 1)
        self.scale = 1
        self.baseMatrix = GLKMatrix4Identity
    }
    
    //Initialize object fields
    init(name: String, tag: String?, objectData: VertexData, _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = GLKVector4Make(xPos, yPos, zPos, 1)
        self.scale = scale
        self.baseMatrix = baseMatrix
        //Conduct other things here
    }
    
    //combine seperated vertex and normal array into a single array for drawing
    func combineVerticesAndNormals(vertexData: [GLfloat], normalData: [GLfloat]){
        
    }
    
    //overloaded init for seperated vertices and normals from blender
    init(name: String, tag: String?, objectData: VertexData, ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = GLKVector4Make(xPos, yPos, zPos, 1)
        self.scale = scale // TODO fix scaling of object
        self.baseMatrix = baseMatrix
        //Conduct other things here
    }
    
    //Deinitialize game object
    deinit {
        print("Object deinitialized");
    }
    
    //Returns the object's vertex data
    func getObjectData() -> VertexData {
        return self.objectData;
    }
    
    //Gets postitions from vertex array
    func getPositionsData() -> [GLfloat] {
        var positions: [GLfloat] = [GLfloat](repeating: GLfloat(), count: objectData.position.count)
        for i in 0..<objectData.position.count {
            positions[i] = objectData.position[i]
        }
        return positions
    }
    
    //Gets normals from vertex array
    func getNormalsData() -> [GLfloat] {
        var normals: [GLfloat] = [GLfloat](repeating: GLfloat(), count: objectData.normal.count)
        for i in 0..<objectData.normal.count {
            normals[i] = objectData.normal[i]
        }
        return normals
    }
    
    //Gets textures from vertex array
    func getTexturesData() -> [GLfloat] {
        var textures: [GLfloat] = [GLfloat](repeating: GLfloat(), count: objectData.texture.count)
        for i in 0..<objectData.texture.count {
            textures[i] = objectData.texture[i]
        }
        return textures
    }
    
    //Scale the base matrix of the object
    func getScaleMatrix() -> GLKMatrix4 {
        return GLKMatrix4MakeScale(
            self.scale,
            self.scale,
            self.scale)
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
        self.position = GLKVector4Make(self.position.x + xMove, self.position.y + yMove, self.position.z + zMove, 0)
    }
}
