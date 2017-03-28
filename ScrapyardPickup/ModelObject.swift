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
    var modelData: VertexData
    
    //Initialize the data
    public init() {
        self.modelData = VertexData(position: [], texture: [], normal: [])
    }
    
    //Sets up postions and normals
    public init(_ positions: [GLfloat], _ normals: [GLfloat]) {
        self.modelData = VertexData(position: [], texture: [], normal: [])
        loadData(positions, normals)
    }
    
    //Sets up postions textures and normals
    public init(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat]) {
        self.modelData = VertexData(position: [], texture: [], normal: [])
        loadData(positions, normals, textures)
    }
    
    //Loads the data from the GLfloat arrays into the model data vertex array (pos and norm only)
    func loadData(_ positions: [GLfloat], _ normals: [GLfloat]) {
        for i in stride(from: 0, to: positions.count, by: 3) {
            if (positions.indices.contains(i)) {
                modelData.position.append(positions[i])
                modelData.position.append(positions[i+1])
                modelData.position.append(positions[i+2])
            }
            if (normals.indices.contains(i)) {
                modelData.normal.append(normals[i])
                modelData.normal.append(normals[i+1])
                modelData.normal.append(normals[i+2])
            }
        }
    }
    
    //Loads the data from the GLfloat arrays into the model data vertex array
    func loadData(_ positions: [GLfloat], _ normals: [GLfloat], _ textures: [GLfloat]) {
        for i in stride(from: 0, to: positions.count, by: 3) {
            if (positions.indices.contains(i)) {
                modelData.position.append(positions[i])
                modelData.position.append(positions[i+1])
                modelData.position.append(positions[i+2])
            }
            if (textures.indices.contains(i)) {
                modelData.texture.append(textures[i])
                modelData.texture.append(textures[i+1])
            }
            if (normals.indices.contains(i)) {
                modelData.normal.append(normals[i])
                modelData.normal.append(normals[i+1])
                modelData.normal.append(normals[i+2])
            }
        }
    }
    
    //Returns the model data vertex array
    public func getModelData() -> VertexData {
        return modelData
    }
    
    //*.obj Parser. Only OBJ files
    public func parseOBJFile(fileName: String) {
        var positions: [GLfloat] = []
        var textures: [GLfloat] = []
        var normals: [GLfloat] = []
        var indices: [GLuint] = []
        // parsing into arrays
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "obj"){
            do {
                let contentsArray = try String(contentsOfFile: filePath).components(separatedBy: "\n")
                for line in 0..<contentsArray.count {
                    if (contentsArray[line].hasPrefix("v ")) {
                        let numbers = contentsArray[line].components(separatedBy: " ")
                        positions.append(Float(numbers[1])!)
                        positions.append(Float(numbers[2])!)
                        positions.append(Float(numbers[3])!)
                    }
                    if (contentsArray[line].hasPrefix("vt ")) {
                        let numbers = contentsArray[line].components(separatedBy: " ")
                        textures.append(Float(numbers[1])!)
                        textures.append(Float(numbers[2])!) // only has 2
                    }
                    if (contentsArray[line].hasPrefix("vn ")) {
                        let numbers = contentsArray[line].components(separatedBy: " ")
                        normals.append(Float(numbers[1])!)
                        normals.append(Float(numbers[2])!)
                        normals.append(Float(numbers[3])!)
                    }
                    if (contentsArray[line].hasPrefix("f ")) {
                        let faces = contentsArray[line].components(separatedBy: " ")
                        for n in 1..<faces.count {
                            let faceNumbers = faces[n].components(separatedBy: "/")
                            indices.append(GLuint(faceNumbers[0])!)
                            if (faceNumbers[1] == "") {
                                indices.append(GLuint(0))
                            } else {
                                indices.append(GLuint(faceNumbers[1])!)
                            }
                            indices.append(GLuint(faceNumbers[2])!)
                        }
                    }
                }
                self.modelData.position = reorder3(data: positions, indices: indices, offset: 0)
                self.modelData.texture = reorder2(data: textures, indices: indices, offset: 1)
                self.modelData.normal = reorder3(data: normals, indices: indices, offset: 2)
            } catch {
                NSLog("File: " + fileName + ".obj file contents could not be loaded")
            }
        } else {
            NSLog("File: " + fileName + ".obj could not be opened");
        }
// TODO: Test this
    }
    //reorder data based on inidices and return the data
    private func reorder3(data: [GLfloat], indices: [GLuint], offset: Int) -> [GLfloat] {
        var dataOut: [GLfloat] = []
        for i in stride(from: offset, to: indices.count, by: 3) {
            dataOut.append(data[(Int(indices[i]) - 1) * 3])
            dataOut.append(data[(Int(indices[i]) - 1) * 3 + 1])
            dataOut.append(data[(Int(indices[i]) - 1) * 3 + 2])
        }
        return dataOut
    }
    
    private func reorder2(data: [GLfloat], indices: [GLuint], offset: Int) -> [GLfloat] {
        if (data.count <= 0) {
            return []
        }
        var dataOut: [GLfloat] = []
        for i in stride(from: offset, to: (indices.count / 3) * 2, by: 3) {
            dataOut.append(data[(Int(indices[i]) - 1) * 3])
            dataOut.append(data[(Int(indices[i]) - 1) * 3 + 1])
        }
        return dataOut
    }
}
