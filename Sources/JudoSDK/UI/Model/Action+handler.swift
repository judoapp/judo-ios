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

import JudoModel
import UIKit
import SafariServices
import os.log

@available(iOS 13.0, *)
extension Action {
    func handle(experience: Experience, node: Node, screen: Screen, data: Any?, urlParameters: [String: String], userInfo: [String: Any], authorize: @escaping (inout URLRequest) -> Void, experienceViewController: ExperienceViewController, screenViewController: ScreenViewController) {
        switch(self.actionType) {
        case .performSegue:
            guard let screen = self.screen else {
                return
            }
            
            switch segueStyle {
            case .modal:
                let viewController = Judo.sharedInstance.navBarViewController(experience, screen, data, urlParameters, userInfo, authorize)
                switch modalPresentationStyle {
                case .sheet:
                    viewController.modalPresentationStyle = .pageSheet
                case .fullScreen:
                    viewController.modalPresentationStyle = .fullScreen
                default:
                    break
                }
                
                screenViewController.present(viewController, animated: true)
            default:
                let viewController = Judo.sharedInstance.screenViewController(experience, screen, data, urlParameters, userInfo, authorize)
                screenViewController.show(viewController, sender: screenViewController)
            }
        case .openURL:
            guard let resolvedURLString = self.url?.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo), let resolvedURL = URL(string: resolvedURLString) else {
                return
            }
            
            if self.dismissExperience ?? false {
                performDismissExperience(experienceViewController: experienceViewController) {
                    UIApplication.shared.open(resolvedURL) { success in
                        if !success {
                            judo_log(.error, "Unable to present unhandled URL: %@", resolvedURL.absoluteString)
                        }
                    }
                }
            } else {
                UIApplication.shared.open(resolvedURL) { success in
                    if !success {
                        judo_log(.error, "Unable to present unhandled URL: %@", resolvedURL.absoluteString)
                    }
                }
            }
        case .presentWebsite:
            guard let resolvedURLString = self.url?.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo), let resolvedURL = URL(string: resolvedURLString) else {
                return
            }
            
            let viewController = SFSafariViewController(url: resolvedURL)
            screenViewController.present(viewController, animated: true)
        case .close:
            screenViewController.dismiss(animated: true)
        case .custom:
            if self.dismissExperience ?? false {
                performDismissExperience(experienceViewController: experienceViewController) {
                    // no-op
                }
            }
        }
    }
    
    func performDismissExperience(experienceViewController: UIViewController, callback: @escaping () -> Void) {
        // we want to dismiss the underlying ExperienceViewController, so we'll ask it's presenting view controller to dismiss it.
        if let presentingViewController = experienceViewController.presentingViewController {
            presentingViewController.dismiss(animated: true) {
                callback()
            }
        } else {
            // ExperienceViewController not presented; likely embedded in a container view as a child view controller.
            callback()
        }
    }
}
