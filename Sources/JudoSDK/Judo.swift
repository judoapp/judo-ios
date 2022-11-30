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

/// This object is the main singleton entry point for most of the Judo SDK's functionality.
///
/// Use ``sharedInstance`` after you initialize the SDK to get access to it.
public final class Judo {
    public let configuration: Configuration
    
    /// Obtain the Judo SDK instance.
    ///
    /// Usable after calling ``initialize(accessToken:domain:)`` or ``initialize(configuration:)``.
    public static var sharedInstance: Judo {
        get {
            guard let instance = _instance else {
                fatalError("Unexpected usage of Judo SDK API before Judo is initialized. Be sure to call `Judo.initialize()` prior to using Judo.")
            }
            return instance
        }
    }
    
    private static var _instance: Judo?

    /// Initialize the Judo SDK given the accessToken and domain name.
    ///
    /// For additional configuration parameters, switch to ``initialize(configuration:)``.
    public static func initialize(accessToken: String, domain: String) {
        precondition(!accessToken.isEmpty, "Missing Judo access token.")
        precondition(!domain.isEmpty, "Judo domain must not be empty string.")
        let configuration = Configuration(
            accessToken: accessToken,
            domain: domain
        )
        
        initialize(configuration: configuration)
    }
    
    /// Initialize the Judo SDK without an accessToken and domain name.
    /// This is intended for bundled experiences.
    ///
    /// For additional configuration parameters, switch to ``initialize(configuration:)``.
    public static func initialize() {
        let configuration = Configuration(
            accessToken: nil,
            domain: nil
        )
        
        initialize(configuration: configuration)
    }
    
    /// Initialize the Judo SDK with the given ``Configuration``.
    public static func initialize(configuration: Configuration) {
        _instance = Judo(configuration: configuration)
    }
    
    let analytics: Analytics?
    
    private init(configuration: Configuration) {
        self.configuration = configuration
        
        if configuration.accessToken != nil, configuration.domain != nil {
            analytics = Analytics()
            
            if #available(iOS 13.0, *) {
                observeScreenViews()
            }
        } else {
            analytics = nil
        }
    }
    
    /// Get the version number of the Judo SDK.
    public let sdkVersion: String = Meta.SDKVersion
    
    /// Get the version number of the Judo SDK.
    public static let sdkVersion: String = Meta.SDKVersion
    
    private var screenViewedObserver: NSObjectProtocol?
    
    @available(iOS 13.0, *)
    private func observeScreenViews() {
        if self.configuration.accessToken == nil, self.configuration.domain == nil {
            return
        }
        
        screenViewedObserver = NotificationCenter.default.addObserver(
            forName: Judo.screenViewedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [unowned self] notification in
                if configuration.domain == nil, configuration.accessToken == nil {
                    return
                }
                
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

    internal lazy var repository: JudoRepository = JudoRepository()

    internal lazy var downloader: AssetsDownloader = AssetsDownloader(cache: assetsURLCache)

    static let userDefaults = UserDefaults(suiteName: "app.judo.JudoSDK")!

    // MARK: Configurable
    
    /// To customize Judo's caching behavior (such as the change the default limits on cache storage), replace this URLCache with a custom configured instance.
    public lazy var urlCache: URLCache = .makeJudoDefaultCache()

    /// Downloaded assets cache.
    public lazy var assetsURLCache: URLCache = .makeJudoAssetsDefaultCache()

    /// This NSCache is used to retain references to images loaded for display in Experiences.  The images are not given calculated costs, so `totalCostLimit` should be in terms of total images, not bytes of memory.
    public lazy var imageCache: NSCache<NSURL, UIImage> = .judoDefaultImageCache()
    
    /// The libdispatch queue used for fetching and decoding images.
    public lazy var imageFetchAndDecodeQueue: DispatchQueue = DispatchQueue(label: "app.judo.ImageFetchAndDecode", attributes: .concurrent)
    
    /// To customize the Nav Bar View Controller, replace this function reference with a custom one that instantiates your own NavBarViewController subclass.
    public lazy var navBarViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: Any], _ authorize: @escaping (inout URLRequest) -> Void) -> NavBarViewController =
        NavBarViewController.init(experience:screen:data:urlParameters:userInfo:authorize:)
    
    /// To customize the Screen View Controller, replace this function reference with a custom one that instantiates your own ScreenViewController subclass.
    public lazy var screenViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: Any], _ authorize: @escaping (inout URLRequest) -> Void) -> ScreenViewController = ScreenViewController.init(experience:screen:data:urlParameters:userInfo:authorize:)
    
    // MARK: Methods
    
    @available(*, deprecated, message: "Synchonization with the Judo Cloud is no longer supported.")
    public func performSync(prefetchAssets: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }
    
    @available(*, deprecated, message: "Synchonization with the Judo Cloud is no longer supported.")
    public func performSync(completion: (() -> Void)? = nil) {
        completion?()
    }
    
    @available(*, deprecated, message: "Manually pre-fetching assets is no longer supported.")
    public func prefetchAssets(completion: (() -> Void)? = nil) {
        completion?()
    }
    
    @available(*, deprecated, message: "Push notifications are no longer needed by the Judo SDK.")
    public func handleDidReceiveRemoteNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }

    @available(*, deprecated, message: "Synchonization with the Judo Cloud is no longer supported.")
    public func registerAppRefreshTask(taskIdentifier: String, timeInterval: TimeInterval = 15 * 60) {
        
    }

    // MARK: Computed Values
    
    internal var domainURL: URL {
        let urlString = configuration.domain ?? ""
        guard let url = URL(string: "https://\(urlString)") else {
            fatalError("Invalid domain '\(urlString)' given to Judo SDK.")
        }
        
        return url
    }
    
    // MARK: Register
    
    @available(*, deprecated, message: "Push notifications are no longer needed by the Judo SDK.")
    public var deviceToken: String? {
        return nil
    }
    
    @available(*, deprecated, message: "Push notifications are no longer needed by in the Judo SDK.")
    public func registeredForRemoteNotifications(deviceToken: Data) {

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
    
    public func identify(userID: String? = nil) {
        let emptyTraits: [String: String] = [:]
        identify(userID: userID, traits: emptyTraits)
    }
    
    public func identify<T: Codable>(userID: String? = nil, traits: T) {
        if let userID = userID {
            Judo.userDefaults.setValue(userID, forKey: "userID")
        }
        
        do {
            let data = try JSONEncoder().encode(traits)
            Judo.userDefaults.setValue(data, forKey: "traits")
        } catch {
            judo_log(.error, "Failed to encode traits")
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
        guard let analytics = analytics else {
            return
        }

        let context = EventContext()
        
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
    
    // MARK: User Behaviour
    
    private var _registeredCustomActionCallbacks: Any?
    
    @available(iOS 13.0, *)
    internal var registeredCustomActionCallbacks: [(CustomActionActivationEvent) -> Void] {
        get {
            (_registeredCustomActionCallbacks as? RegisteredCustomCallbacksHolder)?.callbacks ?? []
        }
        set {
            _registeredCustomActionCallbacks = RegisteredCustomCallbacksHolder(newValue)
        }
    }
    
    /// This is needed to work around issues with stored properties and @available in Swift.
    @available(iOS 13.0, *)
    internal class RegisteredCustomCallbacksHolder {
        init(_ callbacks: [(Judo.CustomActionActivationEvent) -> Void] = []) {
            self.callbacks = callbacks
        }
        
        var callbacks: [(CustomActionActivationEvent) -> Void] = []
    }
    
    /// Describes a user's activation (ie., a tap) of a custom action on a layer in a Judo experience. A value of this type is given to any registered custom action callbacks registered with ``registerCustomActionCallback(_:)``. Use this to implement the behavior for custom buttons and the like.
    ///
    /// This type provides the context for the user activation custom action, giving the node (layer), screen, and experience data model objects in addition to the data context (URL parameters, user info, and data from a Web API data source).
    ///
    /// It also provides a reference to the UIViewController that is presenting the experience, allowing you to do implement your own effects, including dismissing the experience or presenting your own view controllers.
    @available(iOS 13.0, *)
    public struct CustomActionActivationEvent {
        public var node: Node
        public var screen: Screen
        public var experience: Experience
        
        public var metadata: Metadata?

        /// This value can be any of the types one might typically find in decoded JSON, ie., String, Int, dictionaries, arrays, and so on.
        public var data: Any?
        public var urlParameters: [String: String]
        public var userInfo: [String: Any]
        
        /// The Judo-provided UIViewController that hosts the Experience that the user activated (ie., tapped) a layer with a custom action in.
        ///
        /// You can use this reference to present another view controller on top of this one, and/or dismiss the view controller.
        public var viewController: UIViewController
    }
    
    /// Register a callback that the Judo SDK will call when the user taps on a layer with an action type of "custom". Use this to implement the behavior for custom buttons and the like.
    ///
    /// The callback is given a ``CustomActionActivationEvent`` value.
    @available(iOS 13.0, *)
    public func registerCustomActionCallback(_ callback: @escaping (CustomActionActivationEvent) -> Void) {
        registeredCustomActionCallbacks.append(callback)
    }
    
    // MARK: Presentation
    
    public var userInfo: [String: Any] {
        var result = traits?.dictionaryValue ?? [String: Any]()
        
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
    
    /// Attempt to open a Judo URL, returning true if the SDK is going to handle this URL, or returning false if it cannot.
    ///
    /// You can use this to easily route any matching URLs to the Judo SDK just by checking the return value of this method.
    @discardableResult
    public func openURL(_ url: URL, animated: Bool) -> Bool {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host?.lowercased(), let scheme = components.scheme?.lowercased() else {
            return false
        }
        
        // link matching rules:
        // SDK configured with a domain: only match links (of either kind) that match domain.
        // SDK configured without a domain: match ALL universal links, no deep links.

        if (scheme != "https" && scheme != "http") {
            // deep links:
            guard configuration.domain == host else {
                return false
            }
        } else {
            // universal links:
            if configuration.domain != nil && configuration.domain != host {
                return false
            }
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
            self.configuration.viewControllerForPresenting()?.present(
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

public extension URLCache {
    static func makeJudoDefaultCache() -> URLCache {
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

    static func makeJudoAssetsDefaultCache() -> URLCache {
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
