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

import Foundation
import os.log

@available(iOS 13.0, *)
final class AssetsDownloader {

    enum Priority: String, Comparable {
        case low
        case high

        static let `default`: Priority = .low

        static func < (lhs: AssetsDownloader.Priority, rhs: AssetsDownloader.Priority) -> Bool {
            lhs == .low && rhs == .high
        }
    }

    private class FetchTask: Identifiable {

        typealias Completion = (Result<Data, Swift.Error>) -> Void

        let id: String
        let task: URLSessionTask
        let priority: Priority
        private(set) var completionHandlers: [Completion]

        var state: URLSessionTask.State {
            task.state
        }

        var url: URL {
            task.originalRequest!.url!
        }

        init(id: String, task: URLSessionTask, priority: Priority, handler: @escaping Completion) {
            self.id = id
            self.task = task
            self.priority = priority
            self.completionHandlers = [handler]
        }

        func subscribe(_ completion: @escaping Completion) {
            completionHandlers.append(completion)
        }

        func notify(_ result: Result<Data, Swift.Error>) {
            for handler in completionHandlers {
                handler(result)
            }
        }

        func cancel() {
            task.cancel()
        }

        func resume() {
            task.resume()
        }

        func suspend() {
            task.suspend()
        }
    }

    private let lowSession: URLSession
    private let highSession: URLSession
    private var tasks: [FetchTask]
    private var tasksLock: NSLock

    init(cache: URLCache? = nil) {
        let lowPriorityConfiguration = URLSessionConfiguration.default
        lowPriorityConfiguration.httpMaximumConnectionsPerHost = 2
        lowPriorityConfiguration.httpShouldUsePipelining = true
        lowPriorityConfiguration.networkServiceType = .background
        lowPriorityConfiguration.waitsForConnectivity = true
        lowPriorityConfiguration.urlCache = cache
        lowPriorityConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        lowSession = URLSession(configuration: lowPriorityConfiguration)

        let highPriorityConfiguration = URLSessionConfiguration.default
        highPriorityConfiguration.httpShouldUsePipelining = true
        highPriorityConfiguration.networkServiceType = .responsiveData
        highPriorityConfiguration.waitsForConnectivity = true
        highPriorityConfiguration.urlCache = cache
        highPriorityConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        highSession = URLSession(configuration: highPriorityConfiguration)

        tasks = []
        tasksLock = NSLock()
    }

    deinit {
        tasksLock.lock()
        tasks.forEach({ $0.cancel() })
        tasks.removeAll()
        tasksLock.unlock()
    }

    func enqueue(url: URL, priority: Priority) {
        enqueue(url: url, priority: priority, completion: { _ in })
    }

    func enqueue(url: URL, priority: Priority, completion: @escaping (Result<Data, Swift.Error>) -> Void) {
        if let task = tasks.first(where: { $0.task.originalRequest?.url == url && $0.state != .completed }) {
            if task.priority < priority {
                // re-prioritize
                judo_log(.debug, "Re-priotize %@ -> %@ request: %@", task.priority.rawValue, priority.rawValue, url.absoluteString)
                tasks.filter({ $0.id == task.id && $0.state != .canceling }).forEach { $0.cancel() }
                enqueue(url: url, priority: priority, completion: completion)
                return
            } else {
                // URL already on the list, skip duplicate request and register completion handler
                judo_log(.debug, "Enqueue %@ request: %@\t[skip duplicate]", priority.rawValue, url.absoluteString)
                task.subscribe(completion)
                return
            }
        } else {
            judo_log(.debug, "Enqueue %@ request: %@", priority.rawValue, url.absoluteString)
        }

        let taskIdentifier = UUID().uuidString
        let request = URLRequest.assetRequest(url: url)
        let session = priority == .high ? highSession : lowSession
        let urlTask = session.dataTask(with: request) { result in
            self.tasksLock.lock()
            self.tasks.filter({ $0.id == taskIdentifier }).forEach {
                judo_log(.debug, "Did download %@", $0.url.absoluteString)
                $0.notify(Result {
                    try result.get()
                })
            }

            // Remove processed task
            self.tasks.removeAll(where: { $0.id == taskIdentifier && $0.state == .completed })
            self.tasksLock.unlock()

            judo_log(.debug, "%@ download tasks left", "\(self.tasks.count)")

            self.updateQueue()
        }
        urlTask.priority = priority == .high ? 1.0 : 0.5

        tasksLock.lock()
        tasks.append(
            FetchTask(id: taskIdentifier, task: urlTask, priority: priority, handler: completion)
        )
        tasksLock.unlock()

        updateQueue()
    }

    private func updateQueue() {
        tasksLock.lock()
        defer { tasksLock.unlock() }

        // Remove cancelled
        self.tasks.removeAll(where: { $0.state == .canceling })

        let highPriorityTasks = tasks.filter({ $0.priority == .high })
        let lowPriorityTasks = tasks.filter({ $0.priority == .low })

        // Resume high priority tasks always, and let URLSession handle resource
        highPriorityTasks.filter({ $0.state == .suspended }).forEach { task in
            judo_log(.debug, "Resume download %@", task.url.absoluteString)
            task.resume()
        }

        // If high priority queue has tasks in progress, do pause low priority
        let highQueueHasRunningTasks = !highPriorityTasks.isEmpty
        if highQueueHasRunningTasks {
            lowPriorityTasks.filter({ $0.state == .running }).forEach { task in
                judo_log(.debug, "Suspend download %@", task.url.absoluteString)
                task.suspend()
            }
            return
        }

        // Decide about low priority tasks
        tasks.filter({ $0.priority == .low }).enumerated().forEach { (idx, task) in
            if idx < lowSession.configuration.httpMaximumConnectionsPerHost {
                // Resume top tasks
                if task.state == .suspended {
                    judo_log(.debug, "Resume download %@", task.url.absoluteString)
                    task.resume()
                }
            } else {
                // pause waiting tasks
                if task.state == .running {
                    judo_log(.debug, "Suspend download %@", task.url.absoluteString)
                    task.suspend()
                }
            }
        }
    }
}
