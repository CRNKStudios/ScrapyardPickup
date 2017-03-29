//
//  HitBox.swift
//  ScrapyardPickup
//
//  Created by robert moffat on 3/16/17.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import OpenGLES
import GLKit

public class HitBox{
    var left: GLfloat = 0.0;
    var right: GLfloat = 0.0;
    var top: GLfloat = 0.0;
    var bottom: GLfloat = 0.0;
    //front is the side facing the camera
    var front: GLfloat = 0.0;
    //back is side away from the camera
    var back: GLfloat = 0.0;
    
    init(left: GLfloat, right: GLfloat, top: GLfloat, bottom: GLfloat, front: GLfloat, back: GLfloat){
        self.left = left;
        self.right = right;
        self.top = top;
        self.bottom = bottom;
        self.front = front;
        self.back = back;
    }
    
    static func collisionHasOccured(firstPos: Vector4, firstBox: HitBox, secondPos: Vector4, secondBox: HitBox)->Bool{
        let first = HitBox(left: firstBox.left+firstPos.x, right: firstBox.right+firstPos.x, top: firstBox.top+firstPos.y, bottom: firstBox.bottom+firstPos.y, front: firstBox.front+firstPos.z, back: firstBox.back+firstPos.z);
        let second = HitBox(left: secondBox.left+secondPos.x, right: secondBox.right+secondPos.x, top: secondBox.top+secondPos.y, bottom: secondBox.bottom+secondPos.y, front: secondBox.front+secondPos.z, back: secondBox.back+secondPos.z);
        
        //print(first.left);
        //print(first.right);
        
        let firstWidth = first.right-first.left;
        let secondWidth = second.right-second.left;
        
        let firstHeight = first.top-first.bottom;
        let secondHeight = second.top-second.bottom;
        
        let firstDepth = first.front-first.back;
        let secondDepth = second.front-second.back;
        
        if(abs(first.left-second.left)<firstWidth+secondWidth){
            //print("horizontal");
            if(abs(first.bottom-second.bottom)<firstHeight+secondHeight){
                //print("vertical");
                if(abs(first.back-second.back)<firstDepth+secondDepth){
                    //print("depth");
                    return true;
                }
            }
        }
        
        return false;
    }
}
