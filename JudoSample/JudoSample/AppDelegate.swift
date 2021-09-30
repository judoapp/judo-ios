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
import os.log
import BackgroundTasks
import JudoSDK
import JudoModel

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var screenViewedObserver: NSObjectProtocol?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var configuration = Configuration(
            accessToken: "<ACCESS-TOKEN>",
            domain: "myapp.judo.app"
        )
        
        configuration.authorize("api.example.com", with: { request in
            request.setValue("xxx", forHTTPHeaderField: "Example-Token")
        })
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.performSync()
        Judo.sharedInstance.registerAppRefreshTask(taskIdentifier: "app.judo.background.refresh")
        
        application.registerForRemoteNotifications()
        
        trackScreenViews()
        return true
    }
    
    /// Integrate Judo screen views into your existing analytics, messaging and customer data platform.
    func trackScreenViews() {
        if #available(iOS 13.0, *) {
            screenViewedObserver = NotificationCenter.default.addObserver(
                forName: Judo.screenViewedNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { notification in
                    let screen = notification.userInfo!["screen"] as! Screen
                    let experience = notification.userInfo!["experience"] as! Experience
                    let properties = [
                        "screenID": screen.id,
                        "screenName": screen.name ?? "Screen",
                        "experienceID": experience.id,
                        "experienceName": experience.name
                    ]
                    
                    // Amplitude
                    // Amplitude.instance().logEvent("judo screen viewed", withEventProperties: properties)
                    
                    // Braze
                    // Appboy.sharedInstance()?.logCustomEvent("Judo Screen Viewed", withProperties: properties)
                    
                    // Segment
                    // let screenTitle = "\(experience.name) / \(screen.name ?? "Screen")"
                    // Analytics.shared().screen(screenTitle, category: "Judo", properties: properties)
                    
                    print("Screen tracked: \(properties)")
                }
            )
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("Failed to register for remote notifications, because: %@", type: .debug, error.localizedDescription)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Judo.sharedInstance.registeredForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Judo.sharedInstance.handleDidReceiveRemoteNotification(userInfo: userInfo) { result in
            completionHandler(result)
        }
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
