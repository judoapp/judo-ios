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
    ///   - userInfo: Optional properties about the current user which can be used to personalize the experience.
    ///   - authorize: Optional callback to authorize URL reqeusts made by `DataSource`s.
    public init(
        url: URL,
        ignoreCache: Bool = false,
        userInfo: [String: String] = [:],
        authorize: @escaping (inout URLRequest) -> Void = { _ in }
    ) {
        super.init(nibName: nil, bundle: nil)
        
        if #available(iOS 13.0, *) {
            let maybeFetchRequest = FetchRequest(
                url: url,
                ignoreCache: ignoreCache,
                userInfo: userInfo,
                authorize: authorize
            )
            
            if let fetchRequest = maybeFetchRequest {
                fetchExperience(request: fetchRequest)
            }
        }
    }
    
    /// Initialize ExperienceViewController for an Experience URL, for use with a Segue Outlet in a Storyboard.
    /// - Parameters:
    ///   - url: Experience URL
    ///   - coder: An NSCoder
    ///   - ignoreCache: Optional. Ignore cached Experience, if any.
    ///   - userInfo: Optional properties about the current user which can be used to personalize the experience.
    ///   - authorize: Optional callback to authorize URL reqeusts made by `DataSource`s.
    public init?(
        url: URL,
        coder: NSCoder,
        ignoreCache: Bool = false,
        userInfo: [String: String] = [:],
        authorize: @escaping (inout URLRequest) -> Void = { _ in }
    ) {
        super.init(coder: coder)
        
        if #available(iOS 13.0, *) {
            let maybeFetchRequest = FetchRequest(
                url: url,
                ignoreCache: ignoreCache,
                userInfo: userInfo,
                authorize: authorize
            )
            
            if let fetchRequest = maybeFetchRequest {
                fetchExperience(request: fetchRequest)
            }
        }
    }
    
    /// Initialize Experience View Controller with a `Experience`
    /// - Parameters:
    ///   - experience: `Experience` instance
    ///   - screenID: Optional. Override experience's initial screen identifier.
    ///   - urlParameters: Optional parameters from the URL used to launch the experience.
    ///   - userInfo: Optional properties about the current user which can be used to personalize the experience.
    ///   - authorize: Optional callback to authorize URL reqeusts made by `DataSource`s.
    @available(iOS 13.0, *)
    public init(
        experience: Experience,
        screenID initialScreenID: Screen.ID? = nil,
        urlParameters: [String: String] = [:],
        userInfo: [String: String] = [:],
        authorize: @escaping (inout URLRequest) -> Void = { _ in }
    ) {
        super.init(nibName: nil, bundle: nil)
        
        let context = LaunchContext(
            initialScreenID: initialScreenID,
            urlParameters: urlParameters,
            userInfo: userInfo,
            authorize: authorize
        )
        
        presentExperience(experience: experience, context: context)
    }
    
    /// Initialize Experience View Controller with a `Experience`, for use with a Segue Outlet in a Storyboard.
    /// - Parameters:
    ///   - experience: `Experience` instance
    ///   - coder: An NSCoder
    ///   - screenID: Optional. Override experience's initial screen identifier.
    ///   - urlParameters: Optional parameters from the URL used to launch the experience.
    ///   - userInfo: Optional properties about the current user which can be used to personalize the experience.
    ///   - authorize: Optional callback to authorize URL reqeusts made by `DataSource`s.
    @available(iOS 13.0, *)
    public init?(
        experience: Experience,
        coder: NSCoder,
        screenID initialScreenID: Screen.ID? = nil,
        urlParameters: [String: String] = [:],
        userInfo: [String: String] = [:],
        authorize: @escaping (inout URLRequest) -> Void = { _ in }
    ) {
        super.init(coder: coder)
        
        let context = LaunchContext(
            initialScreenID: initialScreenID,
            urlParameters: urlParameters,
            userInfo: userInfo,
            authorize: authorize
        )
        
        presentExperience(experience: experience, context: context)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("ExperienceViewController is supported directly in Interface Builder or Storyboards, instead use a Segue outlet factory method with init?(url:coder:ignoreCache)")
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        children.first
    }

    open override var childForStatusBarHidden: UIViewController? {
        children.first
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
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Fetch and Present
    
    @available(iOS 13.0, *)
    private struct FetchRequest {
        var url: URL
        var ignoreCache: Bool
        var launchContext = LaunchContext()
        
        init?(
            url: URL,
            ignoreCache: Bool,
            userInfo: [String: String],
            authorize: @escaping (inout URLRequest) -> Void
        ) {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            
            launchContext.userInfo = userInfo
            launchContext.authorize = authorize
            
            let queryItems = urlComponents.queryItems
            urlComponents.query = nil
            self.url = urlComponents.url!
            self.ignoreCache = ignoreCache
            
            queryItems?.forEach { queryItem in
                if queryItem.name.uppercased() == "screenID".uppercased() {
                    launchContext.initialScreenID = queryItem.value
                } else {
                    launchContext.urlParameters[queryItem.name] = queryItem.value
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    private struct LaunchContext {
        var initialScreenID: Screen.ID?
        var urlParameters = [String: String]()
        var userInfo = [String: String]()
        var authorize: (inout URLRequest) -> Void = { _ in }
    }
    
    @available(iOS 13.0, *)
    private func fetchExperience(request: FetchRequest) {
        if !request.ignoreCache, let experience = Judo.sharedInstance.urlCache.cachedExperience(url: request.url) {
            presentExperience(
                experience: experience,
                context: request.launchContext
            )
        } else {
            // TODO: needs visual async state while waiting for loading.
            Judo.sharedInstance.repository.retrieveExperience(url: request.url, ignoreCache: request.ignoreCache) { result in
                switch result {
                case .failure(let error):
                    judo_log(.error, "Error while trying to launch Experience: %@", error.debugDescription)
                    
                    if let recoverableError = error as? RecoverableError, recoverableError.canRecover {
                        self.presentRetrieveRetryDialog() {
                            self.fetchExperience(request: request)
                        }
                    } else {
                        self.presentRetrieveErrorDialog()
                    }
                case .success(let experience):
                    self.presentExperience(
                        experience: experience,
                        context: request.launchContext
                    )
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func presentExperience(experience: Experience, context: LaunchContext) {
        let initialScreenID = context.initialScreenID ?? experience.initialScreenID
        
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

        let navViewController = Judo.sharedInstance.navBarViewController(
            experience,
            initialScreen,
            nil,
            context.urlParameters,
            context.userInfo,
            context.authorize
        )
        
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
