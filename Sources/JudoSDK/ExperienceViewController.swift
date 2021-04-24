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
import JudoModel
import os.log

/// Use this View Controller to present Experiences to the user.
///
/// - Tag: ExperienceViewController
open class ExperienceViewController: UIViewController {

    /// Initialize ExperienceViewController for an Experience URL.
    /// - Parameters:
    ///   - url: Experience URL
    ///   - ignoreCache: Optional. Ignore cached Experience, if any.
    public init(url: URL, ignoreCache: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        setExperience(url: url, ignoreCache: ignoreCache)
    }
    
    /// Initialize ExperienceViewController for an Experience URL, for use with a Segue Outlet in a Storyboard.
    /// - Parameters:
    ///   - url: Experience URL
    ///   - coder: An NSCoder
    ///   - ignoreCache: Optional. Ignore cached Experience, if any.
    public init?(url: URL, coder: NSCoder, ignoreCache: Bool = false) {
        super.init(coder: coder)
        setExperience(url: url, ignoreCache: ignoreCache)
    }
    
    /// Initialize Experience View Controller with a `Experience`
    /// - Parameters:
    ///   - experience: `Experience` instance
    ///   - screenID: Optional. Override experience's initial screen identifier.
    @available(iOS 13.0, *)
    public init(experience: Experience, screenID initialScreenID: Screen.ID? = nil) {
        super.init(nibName: nil, bundle: nil)
        loadExperience(experience: experience, initialScreenID: initialScreenID ?? experience.initialScreenID)
    }
    
    /// Initialize Experience View Controller with a `Experience`, for use with a Segue Outlet in a Storyboard.
    /// - Parameters:
    ///   - experience: `Experience` instance
    ///   - coder: An NSCoder
    ///   - screenID: Optional. Override experience's initial screen identifier.
    @available(iOS 13.0, *)
    public init?(experience: Experience, coder: NSCoder, screenID initialScreenID: Screen.ID? = nil) {
        super.init(coder: coder)
        loadExperience(experience: experience, initialScreenID: initialScreenID ?? experience.initialScreenID)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("ExperienceViewController is supported directly in Interface Builder or Storyboards, instead use a Segue outlet factory method with init?(url:coder:ignoreCache)")
    }
    
    private func setExperience(url: URL, ignoreCache: Bool = false) {
        guard #available(iOS 13.0, *) else {
            return
        }
        
        var experienceURL: URL = url
        var requestedInitialScreenID: Screen.ID? = nil
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let screenID = urlComponents.queryItems?.first(where: { $0.name.uppercased() == "screenID".uppercased() })?.value
        {
            requestedInitialScreenID = screenID
            
            urlComponents.query = nil
            experienceURL = urlComponents.url!
        }
        
        if !ignoreCache, let experience = Judo.sharedInstance.urlCache.cachedExperience(url: experienceURL) {
            loadExperience(experience: experience, initialScreenID: requestedInitialScreenID ?? experience.initialScreenID)
            return
        }
        
        retrieveExperience(url: experienceURL, ignoreCache: ignoreCache, initialScreenID: requestedInitialScreenID)
    }
    
    @available(iOS 13.0, *)
    private func retrieveExperience(url: URL, ignoreCache: Bool = false, initialScreenID: Screen.ID?) {
        // TODO: needs visual async state while waiting for loading.
        Judo.sharedInstance.repository.retrieveExperience(url: url, ignoreCache: ignoreCache) { result in
            switch result {
            case .failure(let error):
                judo_log(.error, "Error while trying to launch Experience: %@", error.debugDescription)
                
                if let recoverableError = error as? RecoverableError, recoverableError.canRecover {
                    self.presentRetrieveRetryDialog() {
                        self.retrieveExperience(url: url, initialScreenID: initialScreenID)
                    }
                } else {
                    self.presentRetrieveErrorDialog()
                }
            case .success(let experience):
                self.loadExperience(experience: experience, initialScreenID: initialScreenID ?? experience.initialScreenID)
            }
        }
    }
    
    open override func loadView() {
        if #available(iOS 13.0, *) {
            super.loadView()
        } else {
            super.loadView()
            self.view.backgroundColor = .white
            
            let title = UILabel()
            title.text = NSLocalizedString("iOS 13+ Required", bundle: Bundle.module, comment: "Judo upgrade operating system message title")
            title.font = UIFont.boldSystemFont(ofSize: 18)
            title.textAlignment = .center
            
            let explanation = UILabel()
            explanation.text = NSLocalizedString("Please update your operating system to view this content.", bundle: Bundle.module, comment: "Judo upgrade operating system CTA")
            explanation.numberOfLines = 0
            explanation.textAlignment = .center
            explanation.textColor = .black
            
            let closeButton = UIButton()
            closeButton.setTitle(NSLocalizedString("OK", bundle: Bundle.module, comment: "Judo OK action"), for: .normal)
            closeButton.setTitleColor(.blue, for: .normal)
            closeButton.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
            let stackView = UIStackView(arrangedSubviews: [title, explanation, closeButton])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 16
            
            self.view.addSubview(stackView)
            self.view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor).isActive = true
            self.view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor).isActive = true
            explanation.widthAnchor.constraint(lessThanOrEqualToConstant: 240).isActive = true
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor).isActive = true
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor).isActive = true
        }
    }
    
    /// This method yields the user info hash ([String: String]) that is made available for interpolation into Experience content.
    ///
    /// The default implementation of this method calls a settable closure `Judo.sharedInstance.userInfo()`, which is an easier way to provide custom user info to Experiences without needing to override ScreenViewController.  For more customized integrations that call for customized user info on an Experience basis, override this method.
    open var userInfo: UserInfo {
        return Judo.sharedInstance.userInfo()
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 13.0, *)
    private func loadExperience(experience: Experience, initialScreenID: Screen.ID) {
        // determine which root container is on the path to the initial screen:
        let matchingScreen = experience.nodes.first(where: { $0.id == initialScreenID }) as? Screen
        
        guard let initialScreen = matchingScreen ?? experience.nodes.first(where: { $0 is Screen }) as? Screen else {
            judo_log(.error, "No screen to start the Experience from. Giving up.")
            return
        }

        // Register experience fonts
        experience.fonts.forEach { url in
            Judo.sharedInstance.downloader.enqueue(url: url, priority: .high) { result in
                do {
                    try self.registerFontIfNeeded(data: result.get())
                } catch {
                    judo_log(.error, "Experience Font: ", error.localizedDescription)
                }
            }
        }

        let navViewController = Judo.sharedInstance.navBarViewController(experience, initialScreen, nil, userInfo)
        
        self.restorationIdentifier = "\(experience.id)"
        self.setChildViewController(navViewController)
    }

    private func registerFontIfNeeded(data: Data) throws {
        struct FontRegistrationError: Swift.Error, LocalizedError {
            let message: String

            var errorDescription: String? {
                message
            }
        }

        guard let fontProvider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(fontProvider),
              let fontName = cgFont.postScriptName as String?
        else {
            throw FontRegistrationError(message: "Unable to register font from provided data.")
        }

        let queryCollection = CTFontCollectionCreateWithFontDescriptors(
            [
                CTFontDescriptorCreateWithAttributes(
                    [kCTFontNameAttribute: fontName] as CFDictionary
                )
            ] as CFArray, nil
        )

        let fontExists = (CTFontCollectionCreateMatchingFontDescriptors(queryCollection) as? [CTFontDescriptor])?.isEmpty == false
        if !fontExists {
            if !CTFontManagerRegisterGraphicsFont(cgFont, nil) {
                throw FontRegistrationError(message: "Unable to register font: \(fontName)")
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Judo.didRegisterCustomFontNotification, object: fontName)
            }
        }
    }

    private func presentRetrieveRetryDialog(retry: @escaping () -> Void) {
        let alertController: UIAlertController

        alertController = UIAlertController(
            title: NSLocalizedString("Error", bundle: Bundle.module, comment: "Judo Error Dialog title"),
            message: NSLocalizedString("Failed to load Experience", bundle: Bundle.module, comment: "Judo Failed to load Experience error message"),
            preferredStyle: UIAlertController.Style.alert
        )
        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", bundle: Bundle.module, comment: "Judo Cancel Action"),
            style: UIAlertAction.Style.cancel
        ) { _ in
            alertController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        let retry = UIAlertAction(
            title: NSLocalizedString("Try Again", bundle: Bundle.module, comment: "Judo Try Again Action"),
            style: UIAlertAction.Style.default
        ) { _ in
            alertController.dismiss(animated: true, completion: nil)

            retry()
        }

        alertController.addAction(cancel)
        alertController.addAction(retry)

        present(alertController, animated: true, completion: nil)
    }

    private func presentRetrieveErrorDialog() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Error", bundle: Bundle.module, comment: "Judo Error Title"),
            message: NSLocalizedString("Something went wrong", bundle: Bundle.module, comment: "Judo Something Went Wrong message"),
            preferredStyle: UIAlertController.Style.alert
        )

        let ok = UIAlertAction(
            title: NSLocalizedString("OK", bundle: Bundle.module, comment: "Judo OK Action"),
            style: UIAlertAction.Style.default
        ) { _ in
            alertController.dismiss(animated: false) {
                self.dismiss(animated: true, completion: nil)
            }
        }

        alertController.addAction(ok)

        present(alertController, animated: true, completion: nil)
    }
    
    private func setChildViewController(_ childViewController: UIViewController) {
        if let existingChildViewController = self.children.first {
            existingChildViewController.willMove(toParent: nil)
            existingChildViewController.view.removeFromSuperview()
            existingChildViewController.removeFromParent()
        }
        
        addChild(childViewController)
        childViewController.view.frame = view.bounds
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }

    open override var childForStatusBarStyle: UIViewController? {
        children.first
    }

    open override var childForStatusBarHidden: UIViewController? {
        children.first
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
private struct ExperienceViewControllerRepresentable: UIViewControllerRepresentable {
    var experience: Experience

    func makeUIViewController(context: Context) -> ExperienceViewController {
        let vc = ExperienceViewController(experience: experience)
        return vc
    }

    func updateUIViewController(_ uiViewController: ExperienceViewController, context: Context) {

    }
}


@available(iOS 14.0, *)
struct ExperienceViewController_Previews : PreviewProvider {
    static var previews: some View {
        let experience = try! Experience(decode: testJSON.data(using: .utf8)!)
        ExperienceViewControllerRepresentable(experience: experience)
            .ignoresSafeArea()
            .previewDevice("iPhone 12")
    }

    static let testJSON = """
    {
    }
    """
}

#endif
