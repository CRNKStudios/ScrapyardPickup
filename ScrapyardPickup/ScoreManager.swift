//
//  ScoreManager.swift
//  ScrapyardPickup
//
//  Created by Bob on 2017-03-26.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation

public class ScoreManager {
    class func determineStarRating(score: Int, level:Int) -> Int {
        var rating:Int;
        rating = 0;
        
        // basically, at level 1: 10000 points = 3 stars, and at level 4, 10000 = (10k/4) / (40k/3) = 0 (level failed)
        // to pass at level 4, the user must reach approx 55k points (1 star rating)
        // 3 stars at level 4 is 160k points.
        rating = Int((score / level) / (level * 10000 / 3));
        
        return rating;
    }
}
