//
//  MenuViewController.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-02-21.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    var soundManager: SoundManager = SoundManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundManager.playSound(fileName: "track_2")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NSLog(self.title! + " Appeared")
        soundManager.playSound(fileName: "track_2")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NSLog(self.title! + " Disappeared")
        soundManager.stopSound()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
