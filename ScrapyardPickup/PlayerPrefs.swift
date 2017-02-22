//
//  PlayerPrefs.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-02-21.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

class PlayerPrefs {
    var name: String?
    var score: Int? = 0
    var curLevel: Int = 1
    var levelScores = [Int : Int]()
    init (name: String) {
        self.name = name
    }
    func changeName(name: String) {
        self.name = name
    }
    func getName() -> String {
        return self.name!
    }
    // DEPRICATED
    func setScore(score: Int) {
        self.score = score
    }
    func getScore() -> Int {
        return self.score!
    }
    func incrementLevel() {
        self.curLevel++
    }
    func pushLevelScore(level: Int, score: Int) {
        if let lvl = self.levelScores[level] { // if levl isn't there
            if score > lvl { // if player got a better score than previous
                self.score! += (score - lvl)
                self.levelScores[level] = score
            }
        } else { // add level and score
            self.score! += score
            self.levelScores[level] = score
        }
    }
}
