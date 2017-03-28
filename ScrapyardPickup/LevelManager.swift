//
//  LevelManager.swift
//  ScrapyardPickup
//
//  Created by Bob on 2017-03-26.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation

public class LevelManager {
    static var levelfilename = "leveldata.txt";
    static var baseAmountOfScrap = 20;
    static var baseAmountOfBombs = 5;
    
    // determine's the bomb to scrap spawn ratio
    // call this function when spawning models? 
    class func determineScrapToBombsRatio(level: Int) -> Float {
        let scraptospawn = determineScrapToSpawn(level: level);
        let bombstospawn = determineBombsToSpawn(level: level);
        
        return Float(bombstospawn / scraptospawn);
    }
    
    // call this function to figure out how much scrap to spawn in the level
    // some degree of randomness per level.
    class func determineScrapToSpawn(level: Int) -> Int{
        var scrap:Int;
        scrap = 0;
        let diceRoll = Int(arc4random_uniform(15) + 3); // number from 1 to 3
        
        scrap = Int(baseAmountOfScrap + ((diceRoll * level) / 2));
        
        return scrap;
    }
    
    // call this function to figure out how many bombs to spawn in the level
    // some degree of randomness per level
    class func determineBombsToSpawn(level: Int) -> Int{
        var bombs:Int;
        bombs = 0;
        let diceRoll = Int(arc4random_uniform(4) + 2); // factor of either 1 or 2
        
        bombs = Int(baseAmountOfBombs + ((diceRoll * level) * 2));
        
        return bombs;
    }
    
    // used to get the already achieved stars for a specific level
    class func getStarsForLevel(tlevel:Int)  -> String {
        let temp = getLevelData(level: tlevel);
        let data = temp.components(separatedBy: "X");
        
        return data[1];
    }
    
    class func getLevelData(level:Int) -> String {
        var allLevelData = FileWriter.readFile(filename: levelfilename).components(separatedBy: " ");
        
        return allLevelData[level-1];
        
    }
    
    // level data format:
    // 1X0 2X0 3X0 4X0
    // level'X'stars attained
    class func writeLeveldata(level: Int, stars: Int) {
        let text = "\(level)X\(stars) ";
        
        var data:String;
        var allLevelData : [String];
        
        data = FileWriter.readFile(filename: levelfilename);
        allLevelData = data.components(separatedBy: " ");
                
        allLevelData[level-1] = text;

        var temptxt = "";
        
        for s in allLevelData {
            temptxt += s;
        }
        
        FileWriter.writeFile(filename: levelfilename, contents: temptxt);
    }
}
