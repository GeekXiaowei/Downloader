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
        task?.delegate = self
    }
    
    @IBAction func startDownload(_ sender: UIButton) {
        
        if let task = self.task {
            Downloader.shared.download(task: task)
        }
        
    }
    
    @IBAction func pauseDownload(_ sender: UIButton) {
        
        if let task = self.task {
            Downloader.shared.pauseDownload(task: task)
        }
    }
}

extension ViewController: DownloadTaskDelegate {
    
    func download(_ download: DownloadTask, changeState state: DownloadTaskState) {
//        print(#function, "downloadState: \(state)")
    }
    func download(_ download: DownloadTask, downloaing bytes: Int64, progress: Progress) {
//        print(#function, "bytes: \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))")
    }
    func download(_ download: DownloadTask, completed error: Error?) {
//        print(#function, "Error: \(String(describing: error))")
    }
}


