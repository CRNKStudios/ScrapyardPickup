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

public struct Vector3 {
    var x: GLfloat = 0
    var y: GLfloat = 0
    var z: GLfloat = 0
    var w: GLfloat = 0
}

public struct Vertex {
    var positions: [GLfloat] = []
    var colors: [GLfloat] = []
    var textures: [GLfloat] = []
    var normals: [GLfloat] = []
}

public class GameObject{
    public var name: String // must be defined
    public var tag: String? // can be nil
    var vertices: Vertex
    var position: Vector3 = Vector3(x: 0, y: 0, z: 0, w: 0)
    var scale: Float
    var baseMatrix: GLKMatrix4
    
    var velocity: Vector3 = Vector3(x:0, y:0, z: 0, w: 0);
    
    
    //Initialize object fields
    init(name: String, tag: String?, vertices: Vertex, _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.vertices = vertices
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
    init(name: String, tag: String?, vertices: Vertex, ObjectNormalData: [GLfloat], _ xPos: Float, _ yPos: Float, _ zPos: Float, scale: Float, baseMatrix: GLKMatrix4){
        self.name = name
        self.tag = tag
        self.vertices = vertices
        self.position.x = xPos
        self.position.y = yPos
        self.position.z = zPos
        self.scale = scale
        self.baseMatrix = baseMatrix
    }
    
    //Deinitialize game object
    deinit {
        print("Object deinitialized");
    }
    
    //Returns the object's vertex data
    func getVertices() -> Vertex{
        return self.vertices;
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
    
    func updatePosition(deltaTime: GLfloat){
        self.position.x += self.velocity.x*deltaTime;
        if(self.position.y + self.velocity.y*deltaTime >= -2){
            self.position.y += self.velocity.y*deltaTime;
        }else{
            self.velocity.y=0;
            self.velocity.x = self.velocity.x*0.5;
            self.velocity.z = self.velocity.z*0.5;
            self.position.y = -2;
        }
        self.position.z += self.velocity.z*deltaTime;
    }
    
    func addToVelocities(velx: GLfloat, vely: GLfloat, velz: GLfloat){
        self.velocity.x+=velx;
        self.velocity.y+=vely;
        self.velocity.z+=velz;
    }
}
