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

public struct Configuration {
    public enum AnalyticsMode {
        /// All events are tracked along with any user data passed to the
        /// `Judo.identify(userID:traits:)` method.
        case `default`
        
        /// All events are tracked but only anonymous device data is captured such as locale and
        /// device token.
        case anonymous
        
        /// Only the bare minimum events required for all features to function correctly are tracked  and
        /// only anonymous device data is captured.
        case minimal
        
        /// No events are tracked and no device or user data is sent to Judo's servers. Some features
        /// may not work correctly with this setting.
        case disabled
    }
    
    public var accessToken: String
    public var domain: String
    
    /// Configures which events are tracked by Judo and what data is captured.
    public var analyticsMode = AnalyticsMode.default
    
    /// A closure which returns the root view controller of your app. Judo will use this view controller to
    /// present experiences.
    public var viewControllerForPresenting: () -> UIViewController? = {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            judo_log(.error, "Unable to obtain key window's root view controller")
            return nil
        }
        var findVisibleViewController: ((UIViewController) -> UIViewController?)?
               findVisibleViewController = { viewController in
                   if let presentedViewController = viewController.presentedViewController {
                       return findVisibleViewController?(presentedViewController)
                   }
                   
                   if let navigationController = viewController as? UINavigationController {
                       return navigationController.visibleViewController
                   }
                   
                   if let tabBarController = viewController as? UITabBarController {
                       return tabBarController.selectedViewController
                   }
                   
                   return viewController
               }
               
        guard let visibleViewController = findVisibleViewController?(rootViewController) else {
            judo_log(.error, "Unable to obtain visible view controller")
            return nil
        }
        return visibleViewController
    }
    
    @available(*, deprecated, renamed: "presentingViewController")
    public var rootViewController: () -> UIViewController? {
        get {
            viewControllerForPresenting
        }
        
        set(value) {
            viewControllerForPresenting = value
        }
    }
    
    struct Authorizer {
        var pattern: String
        var block: (inout URLRequest) -> Void
        
        func authorize(_ request: inout URLRequest) {
            block(&request)
        }
    }
    
    var authorizers: [Authorizer]
    
    /// Supply the domain name this authorizer matches against including subdomain. You can optionally supply an asterisk for the subdomain if you want to match against all subdomains.
    public mutating func authorize(_ pattern: String, with block: @escaping (inout URLRequest) -> Void) {
        authorizers.append(
            Authorizer(pattern: pattern, block: block)
        )
    }
    
    public init(accessToken: String, domain: String) {
        self.accessToken = accessToken
        self.domain = domain
        
        authorizers = [
            Authorizer(pattern: "data.judo.app") { request in
                request.setValue(accessToken, forHTTPHeaderField: "Judo-Access-Token")
            }
        ]
    }
}
