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
import JudoSDK
import os.log

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // Properties of the current user. These can be passed to the
    // `ExperienceViewController` to personalize the content in the experience.
    let exampleUserInfo = [
            "userID": "80000516109",
            "firstName": "John",
            "avatar": "https://reqres.in/img/faces/1-image.jpg",
            "pointsBalance": "54,231",
            "subscription": "Premium",
            "memberSince": "2020-07-05T04:04:00Z"
    ]
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let experienceURL = Judo.sharedInstance.experienceURL(from: connectionOptions) {
            let vc = ExperienceViewController(url: experienceURL, userInfo: exampleUserInfo)
            
            // present on top of the view controller you already have configured (eg. in a storyboard):
            DispatchQueue.main.async {
                self.window?.rootViewController?.present(vc, animated: false)
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let experienceURL = Judo.sharedInstance.experienceURL(from: URLContexts) {
            let vc = ExperienceViewController(url: experienceURL, userInfo: exampleUserInfo)
            self.window?.rootViewController?.present(vc, animated: true)
        }
    }
}
