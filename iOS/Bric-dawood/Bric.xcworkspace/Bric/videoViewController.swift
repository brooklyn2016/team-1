//
//  videoViewController.swift
//  Bric
//
//  Created by Dawood Khan on 10/29/16.
//  Copyright © 2016 Dawood Khan. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class videoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    var playerViewController = AVPlayerViewController()
    var playerView = AVPlayer()
    let textCellIdentifier = "VideoCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        /*
        let fileURL = NSURL(fileURLWithPath: "/Users/dawoodkhan/Desktop/Bric/Bric/JAY Z, Kanye West - Otis ft. Otis Redding.mp4")
        playerView = AVPlayer(url: fileURL as URL)
        playerViewController.player = playerView
        self.playerViewController.player?.play()
 */
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath as IndexPath)
        
        let videoURL = NSURL(string: "https://firebasestorage.googleapis.com/v0/b/bric-live.appspot.com/o/fathers_day%2F113DFF12-CB92-41D3-8A4C-9FB461437CF6-NL-merged.mp4?alt=media&token=943a1cc0-2fb1-4244-80a2-92eb8c7114bd")
        //let videoURL = NSURL(fileURLWithPath: "/Users/dawoodkhan/Desktop/Bric/Bric/JAY Z, Kanye West - Otis ft. Otis Redding.mp4")
        let player = AVPlayer(url: videoURL as! URL)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = cell.bounds
        
        cell.layer.addSublayer(playerLayer)
        player.play()
        
        return cell
    }
    
    // MARK:  UITextFieldDelegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return videoArray.count
        return 1
    }
    
    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let row = indexPath.row
        //print(videoArray[row])

    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
