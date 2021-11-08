//
//  ViewController.swift
//  Downloader
//
//  Created by 伟亭徐 on 2021/11/4.
//

import UIKit

class ViewController: UIViewController {
    
    var task: DownloadTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = "https://s3.us-west-2.amazonaws.com/leon.wehear/e11f47f5c9e5cb10175755d7b9532768.mp3"
        
        guard let url = URL(string: urlString) else { return }
        
        task = DownloadTask(url: url)
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let task = self.task {
            Downloader.shared.download(task: task)
        }
        
    }
}


