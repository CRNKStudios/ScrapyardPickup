//
//  SoundManager.swift
//  ScrapyardPickup
//
//  Created by Vincent Huang on 2017-03-28.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation
import AVFoundation

public class SoundManager{
    
    var player: AVAudioPlayer?
    
    func playSound(fileName: String) {
        let url = Bundle.main.url(forResource: fileName, withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer.init(contentsOf: url)
            guard let player = player else { return }
            
            NSLog(fileName);
            
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound(){
        player?.stop()
    }
    
    func setVolume(vol: Float){
        player?.volume = vol
    }
}
