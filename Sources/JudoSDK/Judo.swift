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

import BackgroundTasks
import Combine
import Foundation
import JudoModel
import os.log
import UIKit

public final class Judo {
    public let configuration: Configuration
    
    /// Obtain the Judo SDK instance (after calling [initialize(accessToken:domain:)](x-source-tag://initialize)).
    public static var sharedInstance: Judo {
        get {
            guard let instance = _instance else {
                fatalError("Unexpected usage of Judo SDK API before Judo is initialized. Be sure to call `Judo.initialize()` prior to using Judo.")
            }
            return instance
        }
    }
    
    private static var _instance: Judo?

    /// Initialize the JudoSDK given the accessToken and domain name.
    public static func initialize(accessToken: String, domain: String) {
        precondition(!accessToken.isEmpty, "Missing Judo access token.")
        precondition(!domain.isEmpty, "Judo domain must not be empty string.")
        let configuration = Configuration(
            accessToken: accessToken,
            domain: domain
        )
        
        initialize(configuration: configuration)
    }
    
    public static func initialize(configuration: Configuration) {
        _instance = Judo(configuration: configuration)
    }
    
    let analytics = Analytics()
    
    private init(configuration: Configuration) {
        self.configuration = configuration
        
        if #available(iOS 13.0, *) {
            observeScreenViews()
        }
    }
    
    private var screenViewedObserver: NSObjectProtocol?
    
    @available(iOS 13.0, *)
    private func observeScreenViews() {
        screenViewedObserver = NotificationCenter.default.addObserver(
            forName: Judo.screenViewedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [unowned self] notification in
                switch configuration.analyticsMode {
                case .default, .anonymous:
                    break
                case .minimal, .disabled:
                    return
                }
                
                let screen = notification.userInfo!["screen"] as! Screen
                let experience = notification.userInfo!["experience"] as! Experience
                let properties = try! JSON([
                    "id": screen.id,
                    "name": screen.name ?? "Screen",
                    "experienceID": experience.id,
                    "experienceRevisionID": experience.revisionID,
                    "experienceName": experience.name
                ])
                
                let event = Event.screen(properties: properties)
                track(event: event)
            }
        )
    }
    
    deinit {
        if let screenViewedObserver = self.screenViewedObserver {
            NotificationCenter.default.removeObserver(screenViewedObserver)
        }
    }
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case cannotLaunchExperience(name: String)

        public var description: String {
            switch self {
                case .cannotLaunchExperience(let name):
                    return "Can't launch Experience: \(name)"
            }
        }
    }

    @available(iOS 13.0, *)
    internal lazy var repository: JudoRepository = JudoRepository()
    
    @available(iOS 13.0, *)
    internal lazy var downloader: AssetsDownloader = AssetsDownloader(cache: assetsURLCache)

    static let userDefaults = UserDefaults(suiteName: "app.judo.JudoSDK")!

    // MARK: Configurable
    
    /// To customize Judo's caching behavior (such as the change the default limits on cache storage), replace this URLCache with a custom configured instance.
    public lazy var urlCache: URLCache = .judoDefaultCache()

    /// Downloaded assets cache.
    public lazy var assetsURLCache: URLCache = .judoAssetsDefaultCache()

    /// This NSCache is used to retain references to images loaded for display in Experiences.  The images are not given calculated costs, so `totalCostLimit` should be in terms of total images, not bytes of memory.
    public lazy var imageCache: NSCache<NSURL, UIImage> = .judoDefaultImageCache()
    
    /// The libdispatch queue used for fetching and decoding images.
    public lazy var imageFetchAndDecodeQueue: DispatchQueue = DispatchQueue(label: "app.judo.ImageFetchAndDecode", attributes: .concurrent)
    
    /// To customize the Nav Bar View Controller, replace this function reference with a custom one that instantiates your own NavBarViewController subclass.
    @available(iOS 13.0, *)
    public lazy var navBarViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: String], _ authorize: @escaping (inout URLRequest) -> Void) -> NavBarViewController =
        NavBarViewController.init(experience:screen:data:urlParameters:userInfo:authorize:)
    
    /// To customize the Screen View Controller, replace this function reference with a custom one that instantiates your own ScreenViewController subclass.
    @available(iOS 13.0, *)
    public lazy var screenViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: String], _ authorize: @escaping (inout URLRequest) -> Void) -> ScreenViewController = ScreenViewController.init(experience:screen:data:urlParameters:userInfo:authorize:)
    
    // MARK: Methods
    
    /// Call this method to instruct Judo to (asynchronously) perform a sync.
    /// - Parameters:
    ///   - prefetchAssets: Whether asynchronously prefetch assets found in synced Experiences.
    ///   - completion: Completion handler.
    public func performSync(prefetchAssets: Bool = false, completion: (() -> Void)? = nil) {
        if #available(iOS 13.0, *) {
            repository.syncService.sync {
                if prefetchAssets {
                    self.prefetchAssets() {
                        completion?()
                    }
                } else {
                    completion?()
                }
            }
        } else {
            judo_log(.debug, "Judo runs in skeleton mode on iOS <13, ignoring sync request.")
        }
    }

    private let prefetchQueue = DispatchQueue(label: "app.judo.prefetch-assets")

    /// Asynchronously prefetch (download) assets found in the Experiences fetched from the account.
    /// - Parameter completion: Completion handler.
    
    public func prefetchAssets(completion: (() -> Void)? = nil) {
        // Gather image URLs from known (at least expected)
        // urls (Images) and enqueue to download with low priority
        
        guard #available(iOS 13.0, *) else {
            judo_log(.debug, "Judo runs in skeleton mode on iOS <13, ignoring asset prefetch request.")
            completion?()
            return
        }
        
        let group = DispatchGroup()
        
        group.enter()
        let experienceURLs = repository.syncService.persistentFetchedExperienceURLs
        prefetchQueue.async {
            defer { group.leave() }

            let imageURLs = experienceURLs
                .compactMap {
                    self.urlCache.cachedExperience(url: $0)
                }
                .flatMap {
                    return $0.nodes.flatten()
                }
                .flatMap { node -> [URL] in
                    switch node {
                    case let image as Image:
                        if image.inlineImage == nil && image.darkModeInlineImage == nil {
                            return [image.imageURL, image.darkModeImageURL].compactMap {
                                if let url = $0 {
                                    return URL(string: url)
                                } else {
                                    return nil
                                }
                            }
                        } else {
                            return []
                        }
                    case let pageControl as PageControl:
                        guard case .image(let normalImage, _, let currentImage, _) = pageControl.style else {
                            return []
                        }

                        return [normalImage.imageURL, normalImage.darkModeImageURL, currentImage.imageURL, currentImage.darkModeImageURL].compactMap {
                            if let url = $0 {
                                return URL(string: url)
                            } else {
                                return nil
                            }
                        }
                    default:
                        return []
                    }
                }
                .filter {
                    self.assetsURLCache.cachedResponse(for: URLRequest(url: $0)) == nil
                }

            let fontURLs = experienceURLs
                .compactMap {
                    self.urlCache.cachedExperience(url: $0)
                }
                .flatMap(\.fonts)
                .filter {
                    self.assetsURLCache.cachedResponse(for: URLRequest(url: $0)) == nil
                }

            Set(imageURLs + fontURLs).forEach {
                group.enter()
                self.downloader.enqueue(url: $0, priority: .low) { _ in
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    /// Handle a background notification.
    /// - Parameters:
    ///   - userInfo: A dictionary that contains data from the notification payload.
    ///   - completionHandler: The block to execute after the operation completes.
    public func handleDidReceiveRemoteNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let judoDictionary = userInfo["judo"] as? [AnyHashable: Any], let action = judoDictionary["action"] as? String, action == "SYNC" else {
            completionHandler(.noData)
            return
        }

        performSync(prefetchAssets: true) {
            completionHandler(.newData)
        }
    }

    /// Register and schedule background refresh task.
    ///
    /// Register each task identifier only once. The system kills the app on the second registration of the same task identifier.
    /// - Parameter taskIdentifier: A unique string containing the identifier of the task.
    /// - Parameter timeInterval: The time interval after what run the task.
    public func registerAppRefreshTask(taskIdentifier: String, timeInterval: TimeInterval = 15 * 60) {
        precondition(!taskIdentifier.isEmpty, "Missing task identifier.")
        precondition(!configuration.accessToken.isEmpty, "Missing Judo access token.")
        precondition(!configuration.domain.isEmpty, "Judo domain must not be empty string.")

        if #available(iOS 13.0, *) {
            AppRefreshTask.registerBackgroundTask(taskIdentifier: taskIdentifier, timeInterval: timeInterval)
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { (notification) in
                AppRefreshTask.scheduleJudoRefresh(taskIdentifier: taskIdentifier, timeInterval: timeInterval)
            }
        } else {
            judo_log(.debug, "Judo runs in skeleton mode on iOS <13, ignoring background app refresh task registration request.")
        }
    }

    // MARK: Computed Values
    
    internal var domainURL: URL {
        guard let url = URL(string: "https://\(configuration.domain)") else {
            fatalError("Invalid domain '\(configuration.domain)' given to Judo SDK.")
        }
        
        return url
    }
    
    // MARK: Register
    
    public var deviceToken: String? {
        Judo.userDefaults.string(forKey: "deviceToken")
    }
    
    public func registeredForRemoteNotifications(deviceToken: Data) {
        let hexValue = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Judo.userDefaults.setValue(hexValue, forKey: "deviceToken")
        
        switch configuration.analyticsMode {
        case .default, .anonymous, .minimal:
            let event = Event.register
            track(event: event)
        case .disabled:
            break
        }
    }
    
    // MARK: Identity
    
    public var anonymousID: String {
        if let anonymousID = Judo.userDefaults.string(forKey: "anonymousID") {
            return anonymousID
        } else {
            let anonymousID = UUID().uuidString
            Judo.userDefaults.setValue(anonymousID, forKey: "anonymousID")
            return anonymousID
        }
    }
    
    public var userID: String? {
        Judo.userDefaults.string(forKey: "userID")
    }
    
    public var traits: JSON? {
        guard let data = Judo.userDefaults.data(forKey: "traits") else {
            return nil
        }
        
        return try? JSONDecoder().decode(JSON.self, from: data)
    }
    
    public func identify<T: Codable>(userID: String? = nil, traits: T? = nil) {
        if let userID = userID {
            Judo.userDefaults.setValue(userID, forKey: "userID")
        }
        
        if let traits = traits {
            do {
                let data = try JSONEncoder().encode(traits)
                Judo.userDefaults.setValue(data, forKey: "traits")
            } catch {
                judo_log(.error, "Failed to encode traits")
            }
        }
        
        switch configuration.analyticsMode {
        case .default:
            let event = Event.identify(traits: self.traits)
            track(event: event)
        case .anonymous, .minimal, .disabled:
            break
        }
    }
    
    public func reset() {
        Judo.userDefaults.removeObject(forKey: "anonymousID")
        Judo.userDefaults.removeObject(forKey: "userID")
        Judo.userDefaults.removeObject(forKey: "traits")
    }
    
    // MARK: Events
    
    func track(event: Event) {
        let context = EventContext(deviceToken: deviceToken)
        
        var payload = EventPayload(
            anonymousID: anonymousID,
            event: event,
            context: context
        )
        
        switch configuration.analyticsMode {
        case .default:
            payload.userID = self.userID
        case .anonymous, .minimal, .disabled:
            payload.userID = nil
        }
        
        analytics.addEvent(payload)
    }
    
    // MARK: Presentation
    
    public var userInfo: [String: String] {
        var result = [String: String]()
        
        if case .object(let object) = traits {
            object.forEach { element in
                if case .string(let value) = element.value {
                    result[element.key] = value
                }
            }
        }
        
        result["anonymousID"] = anonymousID
        
        if let userID = userID {
            result["userID"] = userID
        }
        
        return result
    }
    
    @discardableResult
    public func continueUserActivity(_ userActivity: NSUserActivity, animated: Bool) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        return openURL(url, animated: animated)
    }
    
    @discardableResult
    public func openURL(_ url: URL, animated: Bool) -> Bool {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              components.host == configuration.domain else {
            return false
        }
        
        components.scheme = "https"
        
        guard let url = components.url else {
            return false
        }
        
        let viewController = ExperienceViewController(
            url: url,
            userInfo: userInfo,
            authorize: authorize
        )
        
        DispatchQueue.main.async {
            self.configuration.rootViewController()?.present(
                viewController,
                animated: animated,
                completion: nil
            )
        }
        
        return true
    }
    
    func authorize(_ request: inout URLRequest) {
        guard let host = request.url?.host else {
            return
        }
        
        let requestTokens = Array(host.split(separator: "."))
        guard requestTokens.count >= 2 else {
            return
        }
        
        for authorizer in configuration.authorizers {
            let wildcardAndRoot = authorizer.pattern.components(separatedBy: "*.")
            guard let root = wildcardAndRoot.last, wildcardAndRoot.count <= 2 else {
                break
            }
            
            let hasWildcard = wildcardAndRoot.count > 1
            
            if (!hasWildcard && host == authorizer.pattern) || (hasWildcard && (host == root || host.hasSuffix(".\(root)"))) {
                authorizer.authorize(&request)
            }
        }
    }
}

private extension URLCache {
    static func judoDefaultCache() -> URLCache {
        let cacheURL = try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("JudoCache", isDirectory: true)

        if #available(iOS 13.0, *) {
            return URLCache(memoryCapacity: 1_048_576 * 64, diskCapacity: 1_048_576 * 256, directory: cacheURL)
        } else {
            // the cache is entirely unused on earlier than iOS 13 since the SDK does not operate.
            return URLCache()
        }
    }

    static func judoAssetsDefaultCache() -> URLCache {
        let cacheURL = try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("JudoAssetsCache", isDirectory: true)

        if #available(iOS 13.0, *) {
            return URLCache(memoryCapacity: 1_048_576 * 64, diskCapacity: 1_048_576 * 256, directory: cacheURL)
        } else {
            // the cache is entirely unused on earlier than iOS 13 since the SDK does not operate.
            return URLCache()
        }
    }
}

private extension NSCache {
    @objc static func judoDefaultImageCache() -> NSCache<NSURL, UIImage> {
        let c = NSCache<NSURL, UIImage>()
        c.totalCostLimit = 40
        c.name = "Judo Image Cache"
        return c
    }
}

// MARK: Notifications

extension Judo {
    /// Posted when a screen is viewed.
    ///
    /// The Judo SDK posts this notification when the user views a screen in a Judo experience.
    ///
    /// The `userInfo` dictionary contains the following information:
    /// -  `experience`: The `Experience` the screen belongs to.
    /// -  `screen`: The `Screen` that was viewed.
    /// -  `data`: The JSON data available to the screen at the time it was viewed.
    public static let screenViewedNotification: Notification.Name = Notification.Name("JudoScreenViewedNotification")
    
    public static let didRegisterCustomFontNotification = NSNotification.Name("JudoDidRegisterCustomFontNotification")
}
