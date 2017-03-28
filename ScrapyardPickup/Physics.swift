//
//  Physics.swift
//  ScrapyardPickup
//
//  Created by robert moffat on 3/27/17.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation


public class Physics{

    static func calculateCollision( ui: inout Vector3, firstPos: Vector3, firstBox: HitBox, vi: inout Vector3, secondPos: Vector3, secondBox: HitBox, mass1: Float, mass2: Float){
        var M1: Float = mass1;
        var M2: Float = mass2;
        var e: Float = 0.5;
        
        var uiui: Vector3 = Vector3(x:ui.x * ui.x, y:ui.y * ui.y, z:ui.z*ui.z, w:0);
        var vivi: Vector3 = Vector3(x:vi.x * vi.x, y:vi.y * vi.y, z:vi.z*vi.z, w:0);
        
        var xDiff = secondPos.x-firstPos.x;
        var yDiff = secondPos.y-firstPos.y;
        var zDiff = secondPos.z-firstPos.z;
        
        var n: Vector3 = Vector3(x:xDiff,y:yDiff,z:zDiff,w:0);
        n = normalize(vec: n);
        
        
        var t: Vector3 = crossProduct(first: crossProduct(first: n, second: ui), second: n);
        t = normalize(vec: t);
        var uin = dotProduct(first: ui, second: n);
        var vin = dotProduct(first: vi, second: n);
        var vrn = uin-vin;
        var vrnn: Vector3 = Vector3(x:n.x*vrn, y:n.y*vrn, z:n.z*vrn, w:0);
        var uit = dotProduct(first: ui, second: t);
        var vit = dotProduct(first: vi, second: t);
        var uitt: Vector3 = Vector3(x:t.x*uit, y:t.y*uit, z:t.z*uit, w:0);
        var vitt: Vector3 = Vector3(x:t.x*vit, y:t.y*vit, z:t.z*vit, w:0);
        
        var massesPortion: Float = (M1*M2)/(M1+M2);
        
        var JScalar: Float = (e+1)*massesPortion;
        var Jn: Vector3 = Vector3(x:vrnn.x*JScalar, y:vrnn.y*JScalar, z:vrnn.z*JScalar, w:0);
        print(Jn);
        
        var ufnn: Vector3 = Vector3(x:Jn.x/M1+n.x*uin, y:Jn.y/M1+n.y*uin, z:Jn.z/M1+n.z*uin, w:0);
        var vfnn: Vector3 = Vector3(x:Jn.x/M2+n.x*vin, y:Jn.y/M2+n.y*vin, z:Jn.z/M2+n.z*vin, w:0);
        
        var finalUVel = Vector3(x:ufnn.x+uitt.x, y:ufnn.y+uitt.y, z:ufnn.z+uitt.z, w:0);
        var finalVVel = Vector3(x:vfnn.x+vitt.x, y:vfnn.y+vitt.y, z:vfnn.z+vitt.z, w:0);
        
        ui = Vector3(x:ufnn.x+uitt.x, y:ufnn.y+uitt.y, z:ufnn.z+uitt.z, w:0);
        vi = Vector3(x:vfnn.x+vitt.x, y:vfnn.y+vitt.y, z:vfnn.z+vitt.z, w:0);
    }
    
    
    /*
        takes in two vector3s and returns the vector3 cross product of them
     */
    static func crossProduct(first: Vector3, second: Vector3)->Vector3{
        let x = first.y*second.z-first.z*second.y;
        let y = first.z*second.x-first.x*second.z;
        let z = first.x*second.y-first.y*second.x;
        
        return Vector3(x:x,y:y,z:z,w:0);
    }
    
    /*
        Takes in a vector3 and returns that vector normalized
     */
    static func normalize(vec: Vector3)->Vector3{
        let mag = sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z);
        if(mag==0){
            return Vector3(x: 0, y: 0, z: 0, w: 0);
        }
        return Vector3(x: vec.x/mag, y: vec.y/mag, z: vec.z/mag, w: 0);
    }
    
    /*
        Takes in two Vector3s and returns the float dot product
     */
    static func dotProduct(first: Vector3, second:Vector3)->Float{
        return first.x*second.x+first.y*second.y+first.z*second.z;
    }
}
