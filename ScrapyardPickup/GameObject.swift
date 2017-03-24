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
 
    Note: Vincent, when loading in objects, they need to be put into an array of
    Vertex structures. When doing this, make a Vertex object, set position = 
    GLKVector4 (textures in some cases may not be there, but just set to 0).
 
    Example:
    v: 1 0 0
    v: 0 1 0
    v: 0 0 1
    v: 1 0 1
    n: 1 0 0
    n: 0 1 0
 
    f: 1//1 2//1 3//1
    f: 4//1 3//1 2//1
 
    var vertex:[Vertex] = [
        Vertex(
            position:GLKVector4(1, 0, 0, 0),
            texture:GLKVector4(0, 0, 0, 0), // in this case we don't have one
            normal:GLKVector4(1, 0, 0, 0)
        ),
        Vertex(
            position:GLKVector4(0, 1, 0, 0),
            texture:GLKVector4(0, 0, 0, 0),
            normal:GLKVector4(1, 0, 0, 0)
        ),
        Vertex(
            position:GLKVector4(0, 0, 1, 0),
            texture:GLKVector4(0, 0, 0, 0),
            normal:GLKVector4(1, 0, 0, 0)
        ),
        Vertex(
            position:GLKVector4(1, 0, 1, 0),
            texture:GLKVector4(0, 0, 0, 0),
            normal:GLKVector4(1, 0, 0, 0)
        ),
        Vertex(
            position:GLKVector4(0, 0, 1, 0),
            texture:GLKVector4(0, 0, 0, 0),
            normal:GLKVector4(1, 0, 0, 0)
        ),
        Vertex(
            position:GLKVector4(0, 1, 0, 0),
            texture:GLKVector4(0, 0, 0, 0),
            normal:GLKVector4(1, 0, 0, 0)
        )
    ]
 */
public struct Vertex {
    var position: GLKVector4
    var texture: GLKVector4
    var normal: GLKVector4
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
    var objectData: [Vertex]
    var position: GLKVector4 = GLKVector4Make(0.0, 0.0, 0.0, 0.0)
    var scale: Float
    var baseMatrix: GLKMatrix4
    
    
    //Initialize object fields
    init(name: String, tag: String?, objectData: [Vertex], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = GLKVector4Make(xPos, yPos, zPos, 1)
        self.scale = scale
        self.baseMatrix = baseMatrix
    }
    
    //combine seperated vertex and normal array into a single array for drawing
    func combineVerticesAndNormals(vertexData: [GLfloat], normalData: [GLfloat]){
        
    }
    
    //overloaded init for seperated vertices and normals from blender
    init(name: String, tag: String?, objectData: [Vertex], ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = GLKVector4Make(xPos, yPos, zPos, 1)
        self.scale = scale
        self.baseMatrix = baseMatrix
    }
    
    //Deinitialize game object
    deinit {
        print("Object deinitialized");
    }
    
    //Returns the object's vertex data
    func getObjectData() -> [Vertex]{
        return self.objectData;
    }
    
    //Gets postitions from vertex array
    func getPositionsData() -> [GLKVector4] {
        var positions: [GLKVector4] = [GLKVector4](repeating: GLKVector4(), count: objectData.count)
        for i in 0..<objectData.count {
            positions[i] = objectData[i].position
        }
        return positions
    }
    
    //Gets normals from vertex array
    func getNormalsData() -> [GLKVector4] {
        var normals: [GLKVector4] = [GLKVector4](repeating: GLKVector4(), count: objectData.count)
        for i in 0..<objectData.count {
            normals[i] = objectData[i].normal
        }
        return normals
    }
    
    //Gets textures from vertex array
    func getTexturesData() -> [GLKVector4] {
        var textures: [GLKVector4] = [GLKVector4](repeating: GLKVector4(), count: objectData.count)
        for i in 0..<objectData.count {
            textures[i] = objectData[i].texture
        }
        return textures
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
