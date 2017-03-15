//
//  ModelObject.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-03-13.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import GLKit

public class ModelObject {
    var modelData: [Vertex]
    
    public init() {
        self.modelData = []
    }
    
    public init(_ positions: [GLfloat], _ normals: [GLfloat]) {
        self.modelData = [Vertex](repeating: Vertex(position: GLKVector4(), color: GLKVector4(), texture: GLKVector4(), normal: GLKVector4()), count: positions.count)
        loadData(positions, normals)
    }
    
    public init(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat], _ colors: [GLfloat]) {
        self.modelData = [Vertex](repeating: Vertex(position: GLKVector4(), color: GLKVector4(), texture: GLKVector4(), normal: GLKVector4()), count: positions.count)
        loadData(positions, normals, textures, colors)
    }
    
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
            if (colors.indices.contains(i)) {
                modelData[i].color = GLKVector4Make(colors[i], colors[i+1], colors[i+2], 1)
            }
        }
    }
    
    public func getModelData() -> [Vertex] {
        return modelData
    }
}
