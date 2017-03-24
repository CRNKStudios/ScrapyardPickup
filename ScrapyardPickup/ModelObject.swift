//
//  ModelObject.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-03-13.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import GLKit

/**
    ModelObject Class

    All objs are Models. This will setup vertex objects and model objects.
 
    Note: Vincent, when working on the Object loader, look at putting it in 
    here for reference and ease of use (plus makes sence really since they are 
    model objects.
 */
public class ModelObject {
    var modelData: [Vertex]
    
    //Initialize the data
    public init() {
        self.modelData = []
    }
    
    //Sets up postions and normals
    public init(_ positions: [GLfloat], _ normals: [GLfloat]) {
        self.modelData = [Vertex](repeating: Vertex(position: GLKVector4(), texture: GLKVector4(), normal: GLKVector4()), count: positions.count)
        loadData(positions, normals)
    }
    
    //Sets up postions textures and normals
    public init(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat]) {
        self.modelData = [Vertex](repeating: Vertex(position: GLKVector4(), texture: GLKVector4(), normal: GLKVector4()), count: positions.count)
        loadData(positions, normals, textures, colors)
    }
    
    //Loads the data from the GLfloat arrays into the model data vertex array (pos and norm only)
    func loadData(_ positions: [GLfloat], _ normals: [GLfloat]) {
        for i in stride(from: 0, to: positions.count, by: 3) {
            if (positions.indices.contains(i)) {
                modelData[i].position = GLKVector4Make(positions[i], positions[i+1], positions[i+2], 1)
            }
            if (normals.indices.contains(i)) {
                modelData[i].normal = GLKVector4Make(normals[i], normals[i+1], normals[i+2], 1)
            }
        }
    }
    
    //Loads the data from the GLfloat arrays into the model data vertex array
    func loadData(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat], _ colors: [GLfloat]) {
        for i in stride(from: 0, to: positions.count, by: 3) {
            if (positions.indices.contains(i)) {
                modelData[i].position = GLKVector4Make(positions[i], positions[i+1], positions[i+2], 1)
            }
            if (normals.indices.contains(i)) {
                modelData[i].normal = GLKVector4Make(normals[i], normals[i+1], normals[i+2], 1)
            }
            if (textures.indices.contains(i)) {
                modelData[i].texture = GLKVector4Make(textures[i], textures[i+1], textures[i+2], 1)
            }
        }
    }
    
    //Returns the model data vertex array
    public func getModelData() -> [Vertex] {
        return modelData
    }
}
