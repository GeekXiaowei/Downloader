//
//  Downloader.swift
//  Downloader
//
//  Created by 伟亭徐 on 2021/11/4.
//

import UIKit

public class Downloader: NSObject {
    
    public static let shared = Downloader()
    
    public static let backgroundSessionIdentifier = "Downloader.backgroundSessionIdentifier"
    /// 同时下载的最大个数
    public static var maxConcurrentDownloadingCount: Int = 4
    
    public static var allowCellularAccessDownload = true
    
    public static var timeoutInterval: TimeInterval = 30
    
    public lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Downloader.backgroundSessionIdentifier)
        config.allowsCellularAccess = Downloader.allowCellularAccessDownload
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        config.timeoutIntervalForRequest = Downloader.timeoutInterval
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()
    
    public var backgroundCompletion: (() -> Void)?
    
    fileprivate var downloadsPool: [String: Downloadable] = [:]
    
    /// 加入下载任务后默认都进入了准备下载队列
    fileprivate var queuedIds: [String] = []
    /// 正在下载的任务集合，容量大小 maximumDownloadingCount
    fileprivate var activeIds: [String] = []
    /// 被停止的下载任务集合
    fileprivate var stopedIds: [String] = []
    /// 被暂停的下载任务集合
    fileprivate var pausedIds: [String] = []
    
    public func start(download: Downloadable) {
        if downloadsPool.keys.contains(download.identifier) {
            if queuedIds.contains(download.identifier) { return }
            if activeIds.contains(download.identifier) { return }
            if stopedIds.contains(download.identifier) { stopedIds.removeAll{ $0 == download.identifier } }
            if pausedIds.contains(download.identifier) { pausedIds.removeAll{ $0 == download.identifier } }
        }else{
            downloadsPool[download.identifier] = download
        }
        queuedIds.append(download.identifier)
        download.state = .waiting
        execureDownloadingTaskFIFO()
    }
    
    public func pause(download: Downloadable) {
        
        guard queuedIds.contains(download.identifier) || activeIds.contains(download.identifier) else { return }
        
        if queuedIds.contains(download.identifier) {
            download.state = .paused
            queuedIds.removeAll{ $0 == download.identifier }
        }
        
        if activeIds.contains(download.identifier) {
            download.downloadTask?.cancel(byProducingResumeData: { download.resumeData = $0 })
            download.state = .paused
            activeIds.removeAll{ $0 == download.identifier }
        }
        
        pausedIds.append(download.identifier)
        
        execureDownloadingTaskFIFO()
    }
    
    public func cancel(download: Downloadable) {
        
        guard queuedIds.contains(download.identifier) || activeIds.contains(download.identifier) else { return }
        
        if queuedIds.contains(download.identifier) {
            download.state = .stopped
            queuedIds.removeAll{ $0 == download.identifier }
        }
        
        if activeIds.contains(download.identifier) {
            download.downloadTask?.cancel(byProducingResumeData: { download.resumeData = $0 })
            download.state = .stopped
            activeIds.removeAll{ $0 == download.identifier }
        }
        
        stopedIds.append(download.identifier)
        
        execureDownloadingTaskFIFO()
    }
    
    private func execureDownloadingTaskFIFO() {
        
        if let identifier = pausedIds.first,
            activeIds.count < Downloader.maxConcurrentDownloadingCount,
            let download = downloadsPool[identifier] {
            
            activeIds.append(identifier)
            
            if let resumeData = download.resumeData {
                download.downloadTask = session.downloadTask(withResumeData: resumeData)
            }
            
            if download.downloadTask == nil {
                download.downloadTask = session.downloadTask(with: download.remoteUrl)
            }
            
            switch download.state {
            case .completed, .started: break
            default:
                download.state = .started
                download.downloadTask?.resume()
            }
            
            queuedIds.removeAll{ $0 == identifier }
        }
    }
    
    /// originalRequest or currentRequest，通常两者相同，但服务器重定向了初始请求时两者会不同。另外，如果任务是通过 resume data 恢复的，originalRequest为 nil，currentRequest代表当前使用的 url request
    fileprivate func activeDownload(with sessionTask: URLSessionTask) -> Downloadable? {
        let requestUrl = sessionTask.originalRequest == nil ? sessionTask.currentRequest?.url : sessionTask.originalRequest?.url
        var download: Downloadable?
        let activeDownloads = activeIds.map{ downloadsPool[$0] }
        activeDownloads.forEach { if $0?.remoteUrl == requestUrl { download = $0 } }
        return download
    }
}

extension Downloader: URLSessionDownloadDelegate {
    /// 创建NSURLSession使用backgroundSessionConfigurationWithIdentifier方法设置一个标.在应用被杀掉前，iOS系统保存应用下载sesson的信息，在重新启动应用，并且创建和之前相同identifier的session时（苹果通过identifier找到对应的session数据），iOS系统会对之前下载中的任务进行依次回调URLSession:task:didCompleteWithError:方法，之后可以使用上面提到的下载失败时的处理方法进行恢复下载
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        print(#function, #line, "Downloader - ErrorUserInfo: \(String(describing: (error as NSError?)?.userInfo))")
        
        if let download = activeDownload(with: task) {
            if let error = error {
                download.resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
                // downloadTask.error = error
                print(#function, #line, "Downloader - UrlSessionCompleteError: \(String(describing: (error as NSError?)?.userInfo))")
                download.state = .stopped
            }else{
                download.state = .completed
            }
            download.delegate?.download(download, completed: error)
            activeIds.removeAll{ $0 == download.identifier }
            execureDownloadingTaskFIFO()
        }else{
            fatalError("Downloader - UrlSessionCompleteError")
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let download = activeDownload(with: downloadTask), let destination = download.destinationUrl {
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                let directory = destination.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: location, to: destination)
            } catch {
                print(#function, #line, "Downloader - FileError: \(String(describing: (error as NSError?)?.userInfo))")
            }
        }else{
            fatalError("Downloader - urlSessionFinishDownloadError")
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let download = activeDownload(with: downloadTask) {
            let progress = Progress(totalUnitCount: 0)
            progress.completedUnitCount = totalBytesWritten
            progress.totalUnitCount = totalBytesExpectedToWrite
            download.totalBytesCount = totalBytesExpectedToWrite
            download.totalBytesReceived = totalBytesWritten
            download.delegate?.download(download, downloadReceiving: bytesWritten, progress: progress)
        }else{
            fatalError("Downloader - urlSessionDidWriteData")
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("didResumeAtOffset: \(fileOffset), expectedTotalBytes: \(expectedTotalBytes)")
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let backgroundCompletion = self.backgroundCompletion {
            DispatchQueue.main.async(execute: backgroundCompletion)
            self.backgroundCompletion = nil
        }
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Downloader.shared.backgroundCompletion = completionHandler
    }
}
