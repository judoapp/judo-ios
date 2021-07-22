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
//import JudoModel
import JudoSDK

class ViewController: UIViewController {
    @IBAction func presentExperience(_ sender: Any) {
        let url = URL(string: "<JUDO-EXPERIENCE-URL>")!
        Judo.sharedInstance.openURL(url, animated: true)
    }
    
    @IBAction func identify(_ sender: Any) {
        // Pass user ID and custom properties to Judo for personalization
        struct UserTraits: Codable {
            let name: String
            let pointsBalance: Int
            let premiumTier: Bool
            let tags: [String]
        }
        
        Judo.sharedInstance.identify(
            userID: "john@example.com",
            traits: UserTraits(
                name: "John Doe",
                pointsBalance: 50_000,
                premiumTier: true,
                tags: ["foo", "bar", "baz"]
            )
        )
    }
    
    @IBAction func reset(_ sender: Any) {
        // Clear user ID and custom properties
        Judo.sharedInstance.reset()
    }
}
