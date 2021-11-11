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
            
            if let resumeData = self.resumeData {
                //
                
            }else{
                task.resume()
            }
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
        
        task.cancel { resumeData in
            self.resumeData = resumeData
        }
    }
}

public class Downloader: NSObject {
    
    public static let shared = Downloader()
    
    public static let backgroundIdentifier = "DownloaderBackgroundIdentifier"
    /// 同时下载的最大个数
    public static var maximumDownloadingCount: Int = 4
    
    public static var allowsCellularAccess = true
    
    public lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Downloader.backgroundIdentifier)
        config.allowsCellularAccess = Downloader.allowsCellularAccess
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()
    /// 加入下载任务后默认都进入了准备下载队列
    public var downloadTasks:       [DownloadTask] = []
    /// 正在下载的任务集合，容量大小 maximumDownloadingCount
    public var downloadingTasks:    [DownloadTask] = []
    /// 被停止的下载任务集合
    public var stopedDownloadTasks: [DownloadTask] = []
    /// 被暂停的下载任务集合
    public var pauseDownloadTasks:  [DownloadTask] = []
    
    public func download(task: DownloadTask) {
        
        if downloadTasks.contains(task) { return }
        
        if downloadingTasks.contains(task) { return }
        
        if stopedDownloadTasks.contains(task) {
            
        }
        
        if pauseDownloadTasks.contains(task) {
            
            
        }
        
        task.downloadTask = session.downloadTask(with: task.url)
        task.state = .waiting
        downloadTasks.append(task)
        updateDownloadTask()
    }
    
    public func pauseDownload(task: DownloadTask) {
        guard downloadTasks.contains(task) else { return }
        if downloadingTasks.contains(task) {
            task.pause()
            downloadingTasks = downloadingTasks.filter{ $0 !== task }
            stopedDownloadTasks.append(task)
            updateDownloadTask()
        }else{
            
        }
    }
    
    public func removeDownload(task: DownloadTask) {
        
    }
    
    private func updateDownloadTask() {
        if let first = downloadTasks.first, downloadingTasks.count < Downloader.maximumDownloadingCount {
            downloadingTasks.append(first)
            first.start()
        }
    }
    
    fileprivate func downloadingTask(with sessionTask: URLSessionTask) -> DownloadTask? {
        return downloadingTasks.filter({ $0.url == sessionTask.originalRequest?.url }).first
    }
}

extension Downloader: URLSessionDownloadDelegate {
    /// 创建NSURLSession使用backgroundSessionConfigurationWithIdentifier方法设置一个标识.在应用被杀掉前，iOS系统保存应用下载sesson的信息，在重新启动应用，并且创建和之前相同identifier的session时（苹果通过identifier找到对应的session数据），iOS系统会对之前下载中的任务进行依次回调URLSession:task:didCompleteWithError:方法，之后可以使用上面提到的下载失败时的处理方法进行恢复下载
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: \(String(describing: error))")
        
        if let downloadTask = downloadingTask(with: task) {
            if let error = error {
                // 下载发生错误
                if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    // 可以重试的
                }else{
                    
                    // 彻底失败的
                }
            }else{
                
                // 正常下载完成
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("didFinishDownloadingTo: \(location)")
        
        if let task = downloadingTask(with: downloadTask), let destination = task.destination {
            let fileHandle = destination(location)
            let destinationURL = fileHandle.destinationURL
            let options = fileHandle.options
            do {
                if options.contains(.removePreviousFile), FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                if options.contains(.createIntermediateDirectories) {
                    let directory = destinationURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                try FileManager.default.moveItem(at: location, to: destinationURL)
            } catch {
                
                
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        
        let size = ByteCountFormatter.string(fromByteCount: bytesWritten, countStyle: .file)
        
        print("progress: \(progress), totalSize: \(totalSize), size: \(size)")
        
        if let task = downloadingTask(with: downloadTask) {
            let progress = Progress(totalUnitCount: 0)
            progress.completedUnitCount = totalBytesWritten
            progress.totalUnitCount = totalBytesExpectedToWrite
            task.delegate?.download(task, downloaing: bytesWritten, progress: progress)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("didResumeAtOffset: \(fileOffset), expectedTotalBytes: \(expectedTotalBytes)")
    }
}
