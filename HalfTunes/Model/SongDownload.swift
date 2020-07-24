//
//  SongDownload.swift
//  HalfTunes
//
//  Created by Sagun Raj Lage on 7/22/20.
//  Copyright © 2020 raywenderlich. All rights reserved.
//

import SwiftUI

class SongDownload: NSObject, ObservableObject {
    var downloadTask: URLSessionDownloadTask?
    var downloadUrl: URL?
    var resumeData: Data?
    
    @Published var downloadLocation: URL?
    @Published var downloadedAmount: Float = 0
    @Published var state: DownloadState = .waiting
    
    enum DownloadState {
        case waiting, downloading, paused, finished
    }
    
    lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func fetchSongAtUrl(_ item: URL) {
        downloadUrl = item
        downloadTask = urlSession.downloadTask(with: item)
        downloadTask?.resume()
        state = .downloading
    }
    
    func cancel() {
        state = .waiting
        downloadTask?.cancel()
        DispatchQueue.main.async {
            self.downloadedAmount = 0
        }
    }
    
    func pause() {
        downloadTask?.cancel(byProducingResumeData: { (data) in
            DispatchQueue.main.async {
                self.resumeData = data
                self.state = .paused
            }
        })
    }
    
    func resume() {
        guard let resumeData = resumeData else { return }
        downloadTask = self.urlSession.downloadTask(withResumeData: resumeData)
        downloadTask?.resume()
        state = .downloading
    }
}

extension SongDownload: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.downloadedAmount = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            print(self.downloadedAmount)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
            let lastPathComponent = downloadUrl?.lastPathComponent else { fatalError() }
        let destinationUrl = documentsPath.appendingPathComponent(lastPathComponent)
        do {
            if fileManager.fileExists(atPath: destinationUrl.path) {
                try fileManager.removeItem(at: destinationUrl)
            }
            try fileManager.copyItem(at: location, to: destinationUrl)
            DispatchQueue.main.async {
                self.downloadLocation = destinationUrl
                self.state = .finished
            }
        } catch {
            print(error)
        }
    }

}
