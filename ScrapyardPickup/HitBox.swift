//
//  HitBox.swift
//  ScrapyardPickup
//
//  Created by robert moffat on 3/16/17.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation

public class HitBox{
    var left=0.0;
    var right=0.0;
    var top=0.0;
    var bottom=0.0;
    //front is the side facing the camera
    var front=0.0;
    //back is side away from the camera
    var back=0.0;
    
    static func collisionHasOccured(first: HitBox, second: HitBox)->Bool{
        let firstWidth = first.right-first.left;
        let secondWidth = second.right-second.left;
        
        let firstHeight = first.top-first.bottom;
        let secondHeight = second.top-second.bottom;
        
        let firstDepth = first.front-first.back;
        let secondDepth = second.front-second.back;
        
        if(abs(first.left-second.left)<firstWidth+secondWidth){
            print("horizontal");
            if(abs(first.bottom-second.bottom)<firstHeight+secondHeight){
                print("vertical");
                if(abs(first.back-second.back)<firstDepth+secondDepth){
                    print("depth");
                    return true;
                }
            }
        }
        
        return false;
    }
}
