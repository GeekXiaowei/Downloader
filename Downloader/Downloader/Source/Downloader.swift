//
//  Downloader.swift
//  Downloader
//
//  Created by 伟亭徐 on 2021/11/4.
//

import Foundation

extension DownloadTask {
    
    fileprivate func start() {
        guard let task = downloadTask else { return }
        switch state {
        case .completed, .started: break
        default:
            state = .started
            task.resume()
        }
    }
    
    fileprivate func pause() {
        guard let task = downloadTask else { return }
        guard state == .started else { return }
        state = .paused
        task.suspend()
    }
    
    fileprivate func stop() {
        guard let task = downloadTask else { return }
        guard state == .started || state == .paused else { return }
        state = .started
        task.cancel()
    }
}

public class Downloader: NSObject {
    
    public static let shared = Downloader()
    /// 同时下载的最大个数
    public var maximumDownloadingCount: Int = 4
    
    public var session: URLSession!
    
    public var downloadTasks:       [DownloadTask] = []
    /// 正在下载的任务集合，容量大小 maximumDownloadingCount
    public var downloadingTasks:    [DownloadTask] = []
    /// 主动停止或者发生错误的下载任务集合
    public var stopedDownloadTasks: [DownloadTask] = []
    
    public override init() {
        super.init()
        
        
    }
    
    public func download(task: DownloadTask) {
        //TODO: 重复 task 问题
        task.state = .waiting
        downloadTasks.append(task)
        startDownloadTask()
    }
    
    public func pauseDownload(task: DownloadTask) {
        guard downloadTasks.contains(task) else { return }
        if downloadingTasks.contains(task) {
            if task.state == .waiting {
//                task.state =
            }else{
                task.pause()
                downloadingTasks = downloadingTasks.filter{ $0 !== task }
                startDownloadTask()
            }
            
        }
    }
    
    public func stopDownload(task: DownloadTask) {
        
    }
    
    public func removeDownload(task: DownloadTask) {
        
    }
    
    private func startDownloadTask() {
        if let first = downloadTasks.first, downloadingTasks.count < maximumDownloadingCount {
            downloadingTasks.append(first)
            first.start()
        }
    }
}

extension Downloader: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
}
