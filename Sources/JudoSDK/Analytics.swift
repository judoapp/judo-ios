// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

/// Responsible for tracking events needed for Judo's analytics functionality.
final class Analytics {
    let flushAt: Int
    let flushInterval: Double
    let maxBatchSize: Int
    let maxQueueSize: Int
    
    private let urlSession: URLSession
    
    private let serialQueue: Foundation.OperationQueue = {
        let q = Foundation.OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    // The following variables comprise the Analytics state and should only be
    // modified from within an operation on the serial queue.
    private var eventQueue = [EventPayload]()
    private var uploadTask: URLSessionTask?
    private var timer: Timer?
    
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    
    private var cache: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("events").appendingPathExtension("plist")
    }
    
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?
    
    init(flushAt: Int = 20, flushInterval: Double = 30.0, maxBatchSize: Int = 100, maxQueueSize: Int = 1_000) {
        let configuration = URLSessionConfiguration.default
        configuration.networkServiceType = .background
        urlSession = URLSession(configuration: configuration)
        
        self.flushAt = flushAt
        self.flushInterval = flushInterval
        self.maxBatchSize = maxBatchSize
        self.maxQueueSize = maxQueueSize
    
        restoreEvents()
        addObservers()
    }
    
    private func restoreEvents() {
        serialQueue.addOperation {
            judo_log(.debug, "Restoring events from cache...")
            
            guard let cache = self.cache else {
                judo_log(.error, "Cache not found")
                return
            }
            
            if !FileManager.default.fileExists(atPath: cache.path) {
                judo_log(.debug, "Cache is empty, no events to restore")
                return
            }
            
            do {
                let data = try Data(contentsOf: cache)
                self.eventQueue = try PropertyListDecoder().decode([EventPayload].self, from: data)
                judo_log(.debug, "%d event(s) restored from cache", self.eventQueue.count)
            } catch {
                judo_log(.error, "Failed to restore events from cache: %@", error.debugDescription)
            }
        }
    }
    
    private func addObservers() {
        self.didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.startTimer()
        }
        
        self.willResignActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.stopTimer()
        }
        
        self.didEnterBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.beginBackgroundTask()
            self?.flushEvents()
        }
        
        if UIApplication.shared.applicationState == .active {
            self.startTimer()
        }
    }
    
    deinit {
        self.stopTimer()
        
        if let didBecomeActiveObserver = self.didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
        
        if let willResignActiveObserver = self.willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
        }
        
        if let didEnterBackgroundObserver = self.didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(didEnterBackgroundObserver)
        }
    }
    
    func addEvent(_ payload: EventPayload) {
        serialQueue.addOperation {
            if self.eventQueue.count == self.maxQueueSize {
                judo_log(.debug, "Event queue is at capacity (%d) – removing oldest event", self.maxQueueSize)
                self.eventQueue.remove(at: 0)
            }
            
            self.eventQueue.append(payload)
               
            judo_log(.debug, "Added event to queue: %@", payload.event.description)
            judo_log(.debug, "Queue now contains %d event(s)", self.eventQueue.count)
        }
        
        persistEvents()
        
        DispatchQueue.toMain {
            if UIApplication.shared.applicationState == .active {
                self.flushEvents(minBatchSize: self.flushAt)
            } else {
                self.flushEvents()
            }
        }
    }
    
    private func persistEvents() {
        serialQueue.addOperation {
            judo_log(.debug, "Persisting events to cache...")
            
            guard let cache = self.cache else {
                judo_log(.error, "Cache not found")
                return
            }
            
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .xml
                let data = try encoder.encode(self.eventQueue)
                try data.write(to: cache, options: [.atomic])
                judo_log(.debug, "Cache now contains %d event(s)", self.eventQueue.count)
            } catch {
                judo_log(.error, "Failed to persist events to cache: %@", error.debugDescription)
            }
        }
    }
    
    private func flushEvents(minBatchSize: Int = 1) {
        let flushEventsOperation = BlockOperation()
        
        flushEventsOperation.addExecutionBlock { [unowned flushEventsOperation] in
            guard !flushEventsOperation.isCancelled else {
                return
            }
            
            if self.uploadTask != nil {
                judo_log(.debug, "Skipping flush – already in progress")
                return
            }
            
            if self.eventQueue.isEmpty {
                judo_log(.debug, "Skipping flush – no events in the queue")
                return
            }
            
            if self.eventQueue.count < minBatchSize {
                judo_log(.debug, "Skipping flush – less than %d events in the queue", minBatchSize)
                return
            }
            
            let events = Array(self.eventQueue.prefix(self.maxBatchSize))
            let url = URL(string: "https://analytics.judo.app/batch")!
            
            var request = URLRequest.apiRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard !flushEventsOperation.isCancelled else {
                return
            }
            
            do {
                let batch = Batch(events: events)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(batch)
            } catch {
                judo_log(.error, "Unable to encode events for tracking to web API. (Reason: %s", error.debugDescription)
                self.removeEvents(events)
                return
            }
            
            guard !flushEventsOperation.isCancelled else {
                return
            }
            
            judo_log(.debug, "Uploading %d event(s) to server", events.count)
            
            let uploadTask = self.urlSession.dataTask(with: request) { result in
                switch result {
                case .failure(let networkError):
                    switch networkError {
                    case .transportError(let error):
                        judo_log(.error, "Failed to upload events: %s", error.debugDescription)
                        judo_log(.error, "Will retry failed events")
                    case .serverError(let statusCode, let message):
                        judo_log(.error, "Failed to upload events: [%d] %s", statusCode, message)
                        
                        if (400..<500).contains(statusCode) {
                            judo_log(.error, "Discarding failed events")
                            self.removeEvents(events)
                        } else {
                            judo_log(.error, "Will retry failed events")
                        }
                    case .noData:
                        judo_log(.error, "Failed to upload events: Unexpected empty response")
                        judo_log(.error, "Discarding failed events")
                        self.removeEvents(events)
                    }
                case .success:
                    judo_log(.debug, "Successfully uploaded %d event(s)", events.count)
                    self.removeEvents(events)
                }
                
                self.uploadTask = nil
                self.endBackgroundTask()
            }
            
            guard !flushEventsOperation.isCancelled else {
                return
            }
            
            uploadTask.resume()
            self.uploadTask = uploadTask
        }
        
        serialQueue.addOperation(flushEventsOperation)
    }
    
    private func removeEvents(_ eventsToRemove: [EventPayload]) {
        serialQueue.addOperation {
            self.eventQueue = self.eventQueue.filter { event in
                !eventsToRemove.contains { $0.id == event.id }
            }
            
            judo_log(.debug, "Removed %d event(s) from queue – queue now contains %d event(s)", eventsToRemove.count, self.eventQueue.count)
        }
        
        persistEvents()
    }
}

// MARK: Timer

extension Analytics {
    private func startTimer() {
        self.stopTimer()
        
        guard self.flushInterval > 0.0 else {
            return
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
            self?.flushEvents()
        }
    }
    
    private func stopTimer() {
        guard let timer = self.timer else {
            return
        }
        
        timer.invalidate()
        self.timer = nil
    }
}

// MARK: Background task

extension Analytics {
    private func beginBackgroundTask() {
        serialQueue.addOperation {
            self.endBackgroundTask()
        }
        
        serialQueue.addOperation {
            self.backgroundTask = UIApplication.shared.beginBackgroundTask {
                self.serialQueue.cancelAllOperations()
                self.endBackgroundTask()
            }
        }
    }
    
    private func endBackgroundTask() {
        if self.backgroundTask != UIBackgroundTaskIdentifier.invalid {
            let taskIdentifier = UIBackgroundTaskIdentifier(rawValue: self.backgroundTask.rawValue)
            UIApplication.shared.endBackgroundTask(taskIdentifier)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }
}

private struct Batch: Encodable {
    var events: [EventPayload]
    
    private enum CodingKeys: String, CodingKey {
        case batch
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .batch)
    }
}
