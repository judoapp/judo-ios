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
import UIKit
import BackgroundTasks
import JudoModel

public final class Judo {
    /// Access token.
    public let accessToken: String
    
    /// App domain name.
    public let domains: [String]
    
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
    /// - Tag: initialize
    public static func initialize(accessToken: String, domains: String...) {
        Self.initialize(accessToken: accessToken, domains: domains)
    }

    /// Initialize the JudoSDK given the accessToken and domain name.
    internal static func initialize(accessToken: String, domains: [String]) {
        precondition(!accessToken.isEmpty, "Missing Judo access token.")
        precondition(!domains.isEmpty, "Must have at least a single Judo domain.")
        precondition(!domains.contains(where: \.isEmpty), "Judo domains must not be empty strings.")
        _instance = Judo(accessToken: accessToken, domains: domains)
    }

    private init(accessToken: String, domains: [String]) {
        self.accessToken = accessToken
        self.domains = domains
        
        // Flush any outstanding events on initialization.
        if #available(iOS 13.0, *) {
            analytics.flushEvents()
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
    
    @available(iOS 13.0, *)
    internal lazy var analytics: Analytics = Analytics()

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
    public lazy var navBarViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: String]) -> NavBarViewController =
        NavBarViewController.init(experience:screen:data:urlParameters:userInfo:)
    
    /// To customize the Screen View Controller, replace this function reference with a custom one that instantiates your own ScreenViewController subclass.
    @available(iOS 13.0, *)
    public lazy var screenViewController: (_ experience: Experience, _ screen: Screen, _ data: Any?, _ urlParameters: [String: String], _ userInfo: [String: String]) -> ScreenViewController = ScreenViewController.init(experience:screen:data:urlParameters:userInfo:)
    
    // MARK: Methods

    /// Register push notifications token on a server.
    /// - Parameter apnsToken: A globally unique token that identifies this device to APNs.
    public func setPushToken(apnsToken deviceToken: Data) {
        let tokenStringHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        judo_log(.debug, "Registering for Judo remote notifications with token: %@", tokenStringHex)

        let requestBody = RegisterTokenBody(
            deviceID: UIDevice().identifierForVendor?.uuidString ?? "",
            deviceToken: tokenStringHex,
            environment: apsEnvironment
        )
        let jsonEncoder = JSONEncoder()
        let body: Data
        do {
            body = try jsonEncoder.encode(requestBody)
        } catch {
            judo_log(.error, "Unable to encode push token registration request message body")
            return
        }

        var request = URLRequest.judoApi(url: URL(string: "https://devices.judo.app/register")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { result in
            if case .failure(let error) = result {
                judo_log(.error, "Failed to register push token: %@", error.debugDescription)
            }
        }.resume()
    }
    
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
        precondition(!accessToken.isEmpty, "Missing Judo access token.")
        precondition(!domains.isEmpty, "Must have at least a single Judo domain.")

        if #available(iOS 13.0, *) {
            AppRefreshTask.registerBackgroundTask(taskIdentifier: taskIdentifier, timeInterval: timeInterval, accessToken: accessToken, domains: domains)
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { (notification) in
                AppRefreshTask.scheduleJudoRefresh(taskIdentifier: taskIdentifier, timeInterval: timeInterval)
            }
        } else {
            judo_log(.debug, "Judo runs in skeleton mode on iOS <13, ignoring background app refresh task registration request.")
        }
    }
    
    // MARK: URL Conversion Utils
    
    @available(iOS 13.0, *)
    public func experienceURL(from connectionOptions: UIScene.ConnectionOptions) -> URL? {
        if let userActivity = connectionOptions.userActivities.first,
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let webpageURL = userActivity.webpageURL {
            return experienceURL(from: webpageURL)
        } else if let urlContext = connectionOptions.urlContexts.first {
            return experienceURL(from: urlContext.url)
        } else {
            return nil
        }
    }
    
    @available(iOS 13.0, *)
    public func experienceURL(from openURLContexts: Set<UIOpenURLContext>) -> URL? {
        openURLContexts
            .compactMap { openURLContext in
                experienceURL(from: openURLContext.url)
            }
            .first
    }
    
    public func experienceURL(from url: URL) -> URL? {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host,
              domains.contains(host) else {
            return nil
        }
        
        if components.scheme == "https" {
            return url
        } else {
            components.scheme = "https"
            return components.url
        }
    }

    // MARK: Computed Values
    
    internal var domainURLs: [URL] {
        self.domains.map { domain in
            guard let url = URL(string: "https://\(domain)") else {
                fatalError("Invalid domain '\(domain)' given to Judo SDK.")
            }
            return url
        }
    }
    
    internal var apsEnvironment: String {
            #if targetEnvironment(simulator)
            return "SIMULATOR"
            #else
            guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
                judo_log(.error, "Provisioning profile not found")
                return "PRODUCTION"
            }
            
            guard let embeddedProfile = try? String(contentsOfFile: path, encoding: String.Encoding.ascii) else {
                judo_log(.error, "Failed to read provisioning profile at path: %@", path)
                return "PRODUCTION"
            }
            
            let scanner = Scanner(string: embeddedProfile)
            var string: NSString?
            
            guard scanner.scanUpTo("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", into: nil), scanner.scanUpTo("</plist>", into: &string) else {
                judo_log(.error, "Unrecognized provisioning profile structure")
                return "PRODUCTION"
            }
            
            guard let data = string?.appending("</plist>").data(using: String.Encoding.utf8) else {
                judo_log(.error, "Failed to decode provisioning profile")
                return "PRODUCTION"
            }
            
            guard let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] else {
                judo_log(.error, "Failed to serialize provisioning profile")
                return "PRODUCTION"
            }
            
            guard let entitlements = plist["Entitlements"] as? [String: Any], let apsEnvironment = entitlements["aps-environment"] as? String else {
                judo_log(.info, "No entry for \"aps-environment\" found in Entitlements – defaulting to production")
                return "PRODUCTION"
            }
            
            return apsEnvironment.uppercased()
            #endif
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

private struct RegisterTokenBody: Codable {
    var deviceID: String
    var deviceToken: String
    var environment: String
}


// MARK: Notifications

extension Judo {
    /// Subscribe to this event to be informed of when the user views an Experience Screen.
    ///
    /// The following values are available in `userInfo`:
    ///
    /// -  `experience` -> `JudoModel.Experience`
    /// -  `screen` -> `JudoModel.Screen`
    /// -  `data` -> The JSON data from the Data Source associated with the Screen,`[String: AnyHashable]`, where the AnyHashable values can range from `Double`, `String`, `[AnyHashable]`, and `[String: AnyHashable]`.
    /// -  `screenViewController` -> The `ScreenViewController` instance displaying the Screen.
    /// -  `experienceViewController` -> The `ExperienceViewController` instance hosting the entire Experience.
    public static let didViewScreenNotification: Notification.Name = Notification.Name("JudoScreenViewedNotification")
    
    /// Subscribe to this event to be informed of when the user taps/activates an Action.
    ///
    /// The following values are available in `userInfo`:
    ///
    /// -  `experience` -> `JudoModel.Experience`
    /// -  `screen` -> `JudoModel.Screen`
    /// -  `node` -> The `JudoModel.Node` interacted with (tapped) by the user.
    /// -  `data` -> The JSON data from the Data Source associated with the Node,`[String: AnyHashable]`, where the AnyHashable values can range from `Double`, `String`, `[AnyHashable]`, and `[String: AnyHashable]`.
    /// -  `screenViewController` -> The `ScreenViewController` instance displaying the Screen.
    /// -  `experienceViewController` -> The `ExperienceViewController` instance hosting the entire Experience.
    public static let didReceiveActionNotification = NSNotification.Name("JudoActionTappedNotification")
    
    public static let didRegisterCustomFontNotification = NSNotification.Name("JudoDidRegisterCustomFontNotification")
}
