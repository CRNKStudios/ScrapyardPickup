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

public struct Vector4 {
    var x: GLfloat = 0
    var y: GLfloat = 0
    var z: GLfloat = 0
    var w: GLfloat = 1
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
    var position: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 1)
    var velocity: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 1)
    var scale: Float
    var baseMatrix: GLKMatrix4
    
    init() {
        self.name = ""
        self.tag = ""
        self.objectData = VertexData(position: [], texture: [], normal: [])
        self.position = Vector4(x:0, y:0, z:0, w:1)
        self.velocity = Vector4(x:0, y:0, z:0, w:1)
        self.scale = 1
        self.baseMatrix = GLKMatrix4Identity
    }
    
    //Initialize object fields
    init(name: String, tag: String?, objectData: VertexData, _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = Vector4(x:xPos, y:yPos, z:zPos, w:1)
        self.scale = scale
        self.baseMatrix = baseMatrix
    }
    
    //combine seperated vertex and normal array into a single array for drawing
    func combineVerticesAndNormals(vertexData: [GLfloat], normalData: [GLfloat]){
        
    }
    
    //overloaded init for seperated vertices and normals from blender
    init(name: String, tag: String?, objectData: VertexData, ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.objectData = objectData
        self.position = Vector4(x:xPos, y:yPos, z:zPos, w:1)
        self.scale = scale
        self.baseMatrix = baseMatrix
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
        self.position = Vector4(x:self.position.x + xMove, y:self.position.y + yMove, z:self.position.z + zMove, w:0)
    }
    
    func updatePosition(deltaTime: GLfloat){
        self.position.x += self.velocity.x*deltaTime;
        if(self.position.y + self.velocity.y*deltaTime >= -2){
            self.position.y += self.velocity.y*deltaTime;
        }else{
            self.velocity.y=0;
            self.velocity.x = self.velocity.x*0.5;
            self.velocity.z = self.velocity.z*0.5;
//            self.position.y = -2;
        }
        self.position.z += self.velocity.z*deltaTime;
    }
    
    func addToVelocities(velx: GLfloat, vely: GLfloat, velz: GLfloat){
        self.velocity.x+=velx;
        self.velocity.y+=vely;
        self.velocity.z+=velz;
    }
}
