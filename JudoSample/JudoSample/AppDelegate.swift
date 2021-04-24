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
    var sampleViewedObserver: Any!
    var sampleTapObserver: Any!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Judo.initialize(accessToken: "<ACCESS-TOKEN>", domains: "myapp.judo.app")
        Judo.sharedInstance.performSync(prefetchAssets: true)
        Judo.sharedInstance.registerAppRefreshTask(taskIdentifier: "app.judo.background.refresh")
        
        application.registerForRemoteNotifications()
        
        // Example integrations with Judo notifications: (iOS 13 check because the JudoModel API is not available when the SDK is in limp mode on iOS 12 and earlier)
        if #available(iOS 13.0, *) {
            // To listen to the Screen Viewed event from Judo (such as for integration into your own analytics tooling)
            sampleViewedObserver = NotificationCenter.default.addObserver(forName: Judo.didViewScreenNotification, object: nil, queue: nil) { notification in
                print(
                    "Judo Screen Viewed",
                    "Experience ID:", (notification.userInfo!["experience"] as? JudoModel.Experience)?.id ?? "<nil>",
                    ", Experience Name:", (notification.userInfo!["experience"] as? JudoModel.Experience)?.name ?? "<nil>",
                    ", Screen ID:", (notification.userInfo!["screen"] as? JudoModel.Screen)?.id ?? "<nil>",
                    ", Screen Name:", (notification.userInfo!["screen"] as? JudoModel.Screen)?.name ?? "<nil>",
                    ", Data:", notification.userInfo!["data"] as? [String: AnyHashable] ?? "<nil>",
                    ", ScreenViewController instance", notification.userInfo!["screenViewController"] as? ScreenViewController as Any,
                    ", ExperienceViewController instance", notification.userInfo!["experienceViewController"] as? ExperienceViewController as Any
                )
            }
            
            // To listen to the Action Tapped event from Judo (such as for implementing Custom action behaviour, or for integration into your own analytics tooling)
            sampleTapObserver = NotificationCenter.default.addObserver(forName: Judo.didReceiveActionNotification, object: nil, queue: nil) { notification in
                print(
                    "Judo Action Tapped",
                    "Experience ID:", (notification.userInfo!["experience"] as? JudoModel.Experience)?.id ?? "<nil>",
                    "Experience Name:", (notification.userInfo!["experience"] as? JudoModel.Experience)?.name ?? "<nil>",
                    ", Screen ID:", (notification.userInfo!["screen"] as? JudoModel.Screen)?.id ?? "<nil>",
                    ", Screen Name:", (notification.userInfo!["screen"] as? JudoModel.Screen)?.name ?? "<nil>",
                    ", Node ID:", (notification.userInfo!["node"] as? JudoModel.Node)?.id ?? "<nil>",
                    ", Node Name:", (notification.userInfo!["node"] as? JudoModel.Node)?.name ?? "<nil>",
                    ", Data:", notification.userInfo!["data"] as? [String: AnyHashable] ?? "<nil>",
                    ", ScreenViewController instance", notification.userInfo!["screenViewController"] as? ScreenViewController as Any,
                    ", ExperienceViewController instance", notification.userInfo!["experienceViewController"] as? ExperienceViewController as Any
                )
            }
        }
        
        // The `userInfo(_:)` callback allows you to set properties of the current user. These properties can be used to personalize text copy and dynamic URLs within a Judo experience.
        Judo.sharedInstance.userInfo = {
            [
                "userID": "80000516109",
                "firstName": "John",
                "avatar": "https://reqres.in/img/faces/1-image.jpg",
                "pointsBalance": "54,231",
                "subscription": "Premium",
                "memberSince": "2020-07-05T04:04:00Z"
            ]
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("Failed to register for remote notifications, because: %@", type: .debug, error.localizedDescription)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Judo.sharedInstance.setPushToken(apnsToken: deviceToken)
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