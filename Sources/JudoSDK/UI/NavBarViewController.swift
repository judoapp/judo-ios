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

import Combine
import JudoModel
import SwiftUI

@available(iOS 13.0, *)
open class NavBarViewController: UINavigationController, UIScrollViewDelegate {
    private var cancellables = Set<AnyCancellable>()
    
    public init(experience: Experience, screen: Screen, data: Any? = nil, urlParameters: [String: String], userInfo: [String: String], authorize: @escaping (inout URLRequest) -> Void) {
        let screenVC = Judo.sharedInstance.screenViewController(experience, screen, data, urlParameters, userInfo, authorize)
        super.init(rootViewController: screenVC)
        restorationIdentifier = screen.id
        
        switch experience.appearance {
        case .light:
            overrideUserInterfaceStyle = .light
        case .dark:
            overrideUserInterfaceStyle = .dark
        case .auto:
            break
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Judo's NavBarViewController is not supported in Interface Builder or Storyboards.")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        observeLargeTitleDisplay()
    }
    
    // MARK: Status Bar
    
    open override var childForStatusBarStyle: UIViewController? {
        visibleViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        visibleViewController
    }
    
    // MARK: Navigation Bar
    
    // The `setNavigationBarHidden(_:animated:)` method is called automatically
    // by `UIHostingController` when it is added to the controller hierarchy.
    // The locking mechanism below allows us to no-op the calls made by
    // `UIHostingController` while allowing our own calls to function normally.
    
    private var isNavigationBarLocked = true
    
    open override var isNavigationBarHidden: Bool {
        set {
            isNavigationBarLocked = false
            setNavigationBarHidden(newValue, animated: false)

            if newValue {
                navigationBar.prefersLargeTitles = false
            } else {
                navigationBar.prefersLargeTitles = true
            }

            isNavigationBarLocked = true
        }
        
        get {
            super.isNavigationBarHidden
        }
    }
    
    open override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        guard !isNavigationBarLocked else {
            return
        }
        
        super.setNavigationBarHidden(hidden, animated: animated)
    }
    
    private func observeLargeTitleDisplay() {
        navigationBar.publisher(for: \.frame)
            .map { [unowned self] frame in
                frame.height >= largeTitleBreakPoint
            }
            .removeDuplicates()
            .sink { [unowned self] isDisplayingLargeTitle in
                largeTitleDisplayDidChange(isDisplayingLargeTitle)
            }
            .store(in: &cancellables)
    }
    
    private var largeTitleBreakPoint: CGFloat {
        parent?.modalPresentationStyle == .fullScreen ? 60 : 72
    }
    
    private func largeTitleDisplayDidChange(_ isDisplayingLargeTitle: Bool) {
        guard let screenVC = visibleViewController as? ScreenViewController,
              let navBar = screenVC.navBar else {
            return
        }
        
        navigationBar.adjustTintColor(
            navBar: navBar,
            traits: traitCollection,
            isScrolling: !isDisplayingLargeTitle
        )
    }
}
