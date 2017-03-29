//
//  Physics.swift
//  ScrapyardPickup
//
//  Created by robert moffat on 3/27/17.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import OpenGLES

public class Physics{

    static func calculateCollision( ui: inout Vector4, firstPos: Vector4, firstBox: HitBox, vi: inout Vector4, secondPos: Vector4, secondBox: HitBox, mass1: Float, mass2: Float){
        var M1: Float = mass1;
        var M2: Float = mass2;
        var e: Float = 0.5;
        
        var uiui: Vector4 = Vector4(x:ui.x * ui.x, y:ui.y * ui.y, z:ui.z*ui.z, w:0);
        var vivi: Vector4 = Vector4(x:vi.x * vi.x, y:vi.y * vi.y, z:vi.z*vi.z, w:0);
        
        var xDiff = secondPos.x-firstPos.x;
        var yDiff = secondPos.y-firstPos.y;
        var zDiff = secondPos.z-firstPos.z;
        
        var n: Vector4 = Vector4(x:xDiff,y:yDiff,z:zDiff,w:0);
        n = normalize(vec: n);
        
        
        var t: Vector4 = crossProduct(first: crossProduct(first: n, second: ui), second: n);
        t = normalize(vec: t);
        var uin = dotProduct(first: ui, second: n);
        var vin = dotProduct(first: vi, second: n);
        var vrn = uin-vin;
        var vrnn: Vector4 = Vector4(x:n.x*vrn, y:n.y*vrn, z:n.z*vrn, w:0);
        var uit = dotProduct(first: ui, second: t);
        var vit = dotProduct(first: vi, second: t);
        var uitt: Vector4 = Vector4(x:t.x*uit, y:t.y*uit, z:t.z*uit, w:0);
        var vitt: Vector4 = Vector4(x:t.x*vit, y:t.y*vit, z:t.z*vit, w:0);
        
        var massesPortion: Float = (M1*M2)/(M1+M2);
        
        var JScalar: Float = (e+1)*massesPortion;
        var Jn: Vector4 = Vector4(x:vrnn.x*JScalar, y:vrnn.y*JScalar, z:vrnn.z*JScalar, w:0);
        print(Jn);
        
        var ufnn: Vector4 = Vector4(x:Jn.x/M1+n.x*uin, y:Jn.y/M1+n.y*uin, z:Jn.z/M1+n.z*uin, w:0);
        var vfnn: Vector4 = Vector4(x:Jn.x/M2+n.x*vin, y:Jn.y/M2+n.y*vin, z:Jn.z/M2+n.z*vin, w:0);
        
        var finalUVel = Vector4(x:ufnn.x+uitt.x, y:ufnn.y+uitt.y, z:ufnn.z+uitt.z, w:0);
        var finalVVel = Vector4(x:vfnn.x+vitt.x, y:vfnn.y+vitt.y, z:vfnn.z+vitt.z, w:0);
        
        ui = Vector4(x:ufnn.x+uitt.x, y:ufnn.y+uitt.y, z:ufnn.z+uitt.z, w:0);
        vi = Vector4(x:vfnn.x+vitt.x, y:vfnn.y+vitt.y, z:vfnn.z+vitt.z, w:0);
    }
    
    
    /*
        takes in two Vector4s and returns the Vector4 cross product of them
     */
    static func crossProduct(first: Vector4, second: Vector4)->Vector4{
        let x = first.y*second.z-first.z*second.y;
        let y = first.z*second.x-first.x*second.z;
        let z = first.x*second.y-first.y*second.x;
        
        return Vector4(x:x,y:y,z:z,w:0);
    }
    
    /*
        Takes in a Vector4 and returns that vector normalized
     */
    static func normalize(vec: Vector4)->Vector4{
        let mag = sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z);
        if(mag==0){
            return Vector4(x: 0, y: 0, z: 0, w: 0);
        }
        return Vector4(x: vec.x/mag, y: vec.y/mag, z: vec.z/mag, w: 0);
    }
    
    /*
        Takes in two Vector4s and returns the float dot product
     */
    static func dotProduct(first: Vector4, second:Vector4)->Float{
        return first.x*second.x+first.y*second.y+first.z*second.z;
    }
    
    
    static func applyMagnetPull(playerMagnet: PlayerObject, objectToPull: inout GameObject, magnetStrength: GLfloat, pullRadius: GLfloat){
        var xdiff = playerMagnet.position.x-objectToPull.position.x;
        var ydiff = playerMagnet.position.y-objectToPull.position.y;
        var zdiff = playerMagnet.position.z-objectToPull.position.z;
        let dist = sqrt(xdiff*xdiff+ydiff*ydiff+zdiff*zdiff);
        if(dist<pullRadius){
            let magnitude = sqrt(xdiff*xdiff+ydiff*ydiff+zdiff*zdiff);
            xdiff = xdiff/magnitude;
            ydiff = ydiff/magnitude;
            zdiff = zdiff/magnitude;
            objectToPull.addToVelocities(velx: magnetStrength*xdiff, vely: magnetStrength*ydiff, velz: magnetStrength*zdiff);
        }
    }
}
