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
import UIKit

import JudoModel

/// Responsible for tracking events needed for Judo's analytics functionality.
@available(iOS 13.0, *)
final class Analytics {
    init() {
        listeners.append(
            NotificationCenter.default.addObserver(forName: Judo.didViewScreenNotification, object: nil, queue: nil) { [self] notification in
                guard let experience = notification.userInfo!["experience"] as? JudoModel.Experience,
                      let screen = notification.userInfo!["screen"] as? JudoModel.Screen else {
                    assertionFailure()
                    judo_log(.error, "Analytics service did not get expected fields.")
                    return
                }
                
                trackScreenViewed(experience: experience, screen: screen)
            }
        )
    }
    
    /// The persisted event queue.
    ///
    /// Access should be serialized through the operation queue to avoid loss of events and avoiding expensive decodes on the main thread.
    private var queue: [ScreenViewedEvent] {
        get {
            guard let eventJson = Judo.userDefaults.data(forKey: "event-queue") else {
                return []
            }
            do {
                return try jsonDecoder.decode([ScreenViewedEvent].self, from: eventJson)
            } catch {
                judo_log(.error, "Invalid persisted event queue JSON, ignoring. (Reason: %s)", error.debugDescription)
                return []
            }
        }
        set {
            do {
                let eventJson = try jsonEncoder.encode(newValue)
                Judo.userDefaults.setValue(eventJson, forKey: "event-queue")
            } catch {
                judo_log(.error, "Unable to encode and persist new event queue JSON, ignoring update. (Reason: %s)", error.debugDescription)
            }
        }
    }
    
    /// Currently running upload task.
    private var uploadTask: URLSessionTask?
    
    private var listeners: [Any] = []
    
    static var defaultURLSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.networkServiceType = .background
        return configuration
    }
    
    /// URL Session used for upload tasks.
    private var urlSession = URLSession(configuration: defaultURLSessionConfiguration)
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    /// This queue is used to serialize (in the background) event operations.
    private let serialQueue = DispatchQueue(label: "JudoEventQueue", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        
    private func trackScreenViewed(experience: Experience, screen: Screen) {
        let event = ScreenViewedEvent(
            properties: ScreenViewedEvent.Properties(
                experienceID: experience.id,
                experienceName: experience.name,
                experienceRevisionID: experience.revisionID,
                screenID: screen.id,
                screenName: screen.name,
                screenTags: screen.metadata?.tags ?? Set<String>([])
            )
        )
        
        serialQueue.async { [weak self] in
            self?.queue.append(
                event
            )
            self?.flushEvents()
        }
    }
    
    // MARK: Queue & Flushing
    
    public func flushEvents() {
        serialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard self.uploadTask == nil else {
                judo_log(.error, "Event flush already running, ignoring request to do so.")
                return
            }
            
            guard !self.queue.isEmpty else {
                return
            }
            
            var request = URLRequest.judoApi(
                url: URL(string: "https://analytics.judo.app/track")!
            )
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let eventsToSend = self.queue
            do {
                let httpBody = try self.jsonEncoder.encode(eventsToSend)
                request.httpBody = httpBody
            } catch {
                judo_log(.error, "Unable to encode events for tracking to web API. (Reason: %s", error.debugDescription)
                self.dropEvents(events: eventsToSend)
                return
            }
            
            self.uploadTask = self.urlSession.dataTask(with: request) { (result: Result<Data, URLSession.NetworkError>) in
                switch result {
                case .failure(let networkError):
                    switch networkError {
                    case .transportError(let error):
                        judo_log(.error, "Transport error submitting events, retaining events for a subsequent attempt. Reason: %s", error.debugDescription)
                    case .serverError(let statusCode, let message):
                        if (400..<500).contains(statusCode) {
                            judo_log(.error, "Server reports bad request while submitting events, dropping the events. Status code %d, reason: %s", statusCode, message)
                            self.dropEvents(events: eventsToSend)
                        } else {
                            judo_log(.error, "Temporary server error while submitting events, retaining events for a subsequent attempt. Status code %d, reason: %s", statusCode, message)
                        }
                    case .noData:
                        judo_log(.error, "Unexpected empty response, dropping the events.")
                        self.dropEvents(events: eventsToSend)
                    }
                case .success(_):
                    judo_log(.debug, "Successfully tracked %d events.", eventsToSend.count)
                    self.dropEvents(events: eventsToSend)
                }
                DispatchQueue.main.async {
                    self.uploadTask = nil
                }
            }
            self.uploadTask?.resume()
        }
    }
    
    private func dropEvents(events: [ScreenViewedEvent]) {
        let idsToDrop = Set(events.map(\.id))
        self.serialQueue.async {
            self.queue = self.queue.filter { event in
                !idsToDrop.contains(event.id)
            }
        }
    }
    
    struct ScreenViewedEvent: Codable {
        var id = UUID()
        var timestamp = Date()
        var name = "Screen Viewed"
        var deviceID = UIDevice.current.identifierForVendor
        var properties: Properties
        var context: Context = Context()
        
        struct Properties: Codable {
            var experienceID: String
            var experienceName: String
            var experienceRevisionID: String
            var screenID: String
            var screenName: String?
            var screenTags: Set<String>
        }
        
        struct Context: Codable {
            var locale = Locale.current.identifier
            var os: OS = OS()

            struct OS: Codable {
                var name = "iOS"
                var version = UIDevice.current.systemVersion
            }
        }
    }
}
