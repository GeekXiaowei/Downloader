//
//  ViewController.swift
//  Downloader
//
//  Created by 伟亭徐 on 2021/11/4.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        let urlString = "https://s3.us-west-2.amazonaws.com/leon.wehear/e11f47f5c9e5cb10175755d7b9532768.mp3"
        
        if let requestUrl = URL(string: urlString) {
            
            let request = URLRequest(url: requestUrl)
            
            let downloadTask = session.downloadTask(with: request)
            
            downloadTask.resume()
        }
        
        
    }


}

extension ViewController: URLSessionDownloadDelegate {
    
    /// 下载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        print("didCompleteWithError: \(String(describing: error?.localizedDescription))")
        

    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo: \(location)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("didWriteData: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("didResumeAtOffset: \(fileOffset), expectedTotalBytes: \(expectedTotalBytes)")
    }
}

