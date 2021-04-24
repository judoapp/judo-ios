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
import os
import UIKit

extension UIApplication {
    /// This is an extension method offered by the Judo SDK that allows you to present a View Controller modally on top of the rest of your app from a non-UI context such as an AppDelegate method for receiving a tapped push notification, opening a deep link, etc. You may use this to present the [ExperienceViewController](x-source-tag://ExperienceViewController).
    ///
    /// It makes certain assumptions about detecting the currently active Scene.
    public func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        // Check if `viewControllerToPresent` is already presented
        
        if viewControllerToPresent.isBeingPresented || viewControllerToPresent.presentingViewController != nil {
            completion?()
            return
        }
        
        // If `viewControllerToPresent` is embedded in a `UITabBarController`, set the active tab
        
        if let tabBarController = viewControllerToPresent.tabBarController {
            tabBarController.selectedViewController = viewControllerToPresent
            completion?()
            return
        }
        
        // Presenting `viewControllerToPresent` inside a container other than `UITabBarController` is not supported at this time
        
        if viewControllerToPresent.parent != nil {
            judo_log(.default, "Failed to present viewControllerToPresent - already presented in an unsupported container")
            completion?()
            return
        }
        
        // The `viewControllerToPresent` is not part of the display hierarchy – present it modally
        
        // Find the currently visible view controller and use it as the presenter.
        
        guard let keyWindow = self.windows.first(where: \.isKeyWindow), let rootViewController = keyWindow.rootViewController else {
            judo_log(.error, "Failed to present viewControllerToPresent - rootViewController not found")
            completion?()
            return
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
            judo_log(.error, "Failed to present `viewControllerToPresent` - visible view controller not found")
            completion?()
            return
        }
        
        visibleViewController.present(viewControllerToPresent, animated: flag) {
            completion?()
        }
    }
}
