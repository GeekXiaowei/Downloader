//
//  Downloadable.swift
//  Downloadable
//
//  Created by 伟亭徐 on 2021/11/4.
//

import Foundation

/// 下载状态枚举
public enum DownloadableState {
    case stopped     // 创建下载任务后处在 stopped 状态
    case waiting     // 加入下载队列后处在 waiting 状态
    case started     // 开始下载任务
    case paused      // 下载任务被主动暂停
    case completed   // 下载任务完成下载
}

///  下载过程中回调一些事件
public protocol DownloadableDelegate: AnyObject {
    
    func download(_ download: Downloadable, changeState state: DownloadableState)
    func download(_ download: Downloadable, downloadReceiving bytesCount: Int64, progress: Progress)
    func download(_ download: Downloadable, completed error: Error?)
}

public protocol Downloadable: AnyObject {
    
    var identifier: String { get }
    var remoteUrl: URL { get }
    var delegate: DownloadableDelegate? { get set }
    var state: DownloadableState { get set}
    var totalBytesReceived: Int64 { get set }
    var totalBytesCount: Int64 { get set }
    var progress: Progress { get }
    var resumeData: Data? { get set }
    var downloadTask: URLSessionDownloadTask? { get set }
    var destinationUrl: URL? { get }
}




