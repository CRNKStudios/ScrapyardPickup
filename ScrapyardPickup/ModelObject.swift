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
    var v: Vertex = Vertex()
    
    public init() {
        v.positions = []
        v.normals = []
        v.textures = []
        v.colors = []
    }
    
    public init(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat], _ colors: [GLfloat]) {
        v.positions = positions
        v.normals = normals
        v.textures = textures
        v.colors = colors
    }
    
    public func getVertexArray() -> Vertex {
        return v
    }
}
