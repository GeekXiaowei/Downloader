//
//  DownloadTask.swift
//  DownloadTask
//
//  Created by 伟亭徐 on 2021/11/4.
//

import Foundation

/// 下载状态枚举
public enum DownloadTaskState {
    case stopped     // 创建下载任务后处在 stopped 状态
    case waiting     // 加入下载队列后处在 waiting 状态
    case started     // 开始下载任务
    case paused      // 下载任务被主动暂停
    case completed   // 下载任务完成下载
}

///  下载过程中回调一些事件
public protocol DownloadTaskDelegate: AnyObject {
    
    func download(_ download: DownloadTask, changeState state: DownloadTaskState)
    func download(_ download: DownloadTask, completedWithError: Error?)
    func download(_ download: DownloadTask, didReceiveData data: Data, progress: Float)
}

/// 借鉴 Alamofire 设置目标存储地址的思路

public class DownloadTask: NSObject {
    
    public var delegate: DownloadTaskDelegate?
    public var state: DownloadTaskState = .stopped {
        didSet{
            delegate?.download(self, changeState: state)
        }
    }
    
    public var totalBytesReceived: Int64 = 0
    public var totalBytesCount: Int64 = 0
    public var downloadingBytesRate: Int64 = 0
    
    public var progress: Float { totalBytesCount == 0 ? 0 : min(1.0, Float(totalBytesReceived)/Float(totalBytesCount)) }
    
    public var downloadTask: URLSessionDownloadTask?
    public var resumeData: Data?
    
    public let url: URL
    
    public init(url: URL) {
        self.url = url
        super.init()
    }
    
}



