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
import SwiftUI

// MARK: - UIHostingController

@available(iOS 13.0, *)
extension UIHostingController {
    convenience init(rootView: Content, ignoreSafeArea: Bool) {
        self.init(rootView: rootView)

        if ignoreSafeArea {
            disableSafeArea()
        }
    }

    private func disableSafeArea() {
        guard let viewClass = object_getClass(view) else { return }

        let viewSubclassName = String(
            cString: class_getName(viewClass)
        ).appending("_IgnoreSafeArea")

        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
        } else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else {
                return
            }

            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else {
                return
            }

            if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    return .zero
                }

                class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
            }

            objc_registerClassPair(viewSubclass)
            object_setClass(view, viewSubclass)
        }
    }
}

// MARK: - UINavigationBar

@available(iOS 13.0, *)
extension UINavigationBar {
    func adjustTintColor(navBar: NavBar, traits: UITraitCollection, isScrolling: Bool = false) {
        let buttonColor: ColorVariants
        if isScrolling, let alternateAppearance = navBar.alternateAppearance {
            buttonColor = alternateAppearance.buttonColor
        } else {
            buttonColor = navBar.appearance.buttonColor
        }

        tintColor = buttonColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )
    }
}

// MARK: - UINavigationItem

@available(iOS 13.0, *)
extension UINavigationItem {
    func configure(navBar: NavBar, stringTable: StringTable, data: JSONObject?, userInfo: UserInfo, traits: UITraitCollection, buttonHandler: @escaping (NavBarButton) -> Void) {

        title = stringTable.resolve(key: navBar.title).evaluatingExpressions(data: data, userInfo: userInfo)

        hidesBackButton = navBar.hidesBackButton

        switch navBar.titleDisplayMode {
        case .large:
            largeTitleDisplayMode = .always
            configureLargeAppearance(navBar: navBar, traits: traits)
        case .inline:
            largeTitleDisplayMode = .never
            configureInlineAppearance(navBar: navBar, traits: traits)
        }

        leftBarButtonItems = navBar.children
            .compactMap { $0 as? NavBarButton }
            .filter { $0.placement == .leading }
            .map { navBarButton in
                UIBarButtonItem(navBarButton: navBarButton, stringTable: stringTable, data: data, userInfo: userInfo) {
                    buttonHandler(navBarButton)
                }
            }

        rightBarButtonItems = navBar.children
            .compactMap { $0 as? NavBarButton }
            .filter { $0.placement == .trailing }
            .map { navBarButton in
                UIBarButtonItem(navBarButton: navBarButton, stringTable: stringTable, data: data, userInfo: userInfo) {
                    buttonHandler(navBarButton)
                }
            }
            .reversed()
    }

    func configureInlineAppearance(navBar: NavBar, traits: UITraitCollection, isScrolling: Bool = false) {
        guard navBar.titleDisplayMode == .inline else {
            return
        }

        let navBarAppearance: NavBar.Appearance
        if isScrolling, let alternateAppearance = navBar.alternateAppearance {
            navBarAppearance = alternateAppearance
        } else {
            navBarAppearance = navBar.appearance
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureFonts(navBar: navBar)
        appearance.configureBackground(background: navBarAppearance.background, traits: traits)
        appearance.configureButtonColor(appearance: navBarAppearance, traits: traits)
        appearance.configureTitleColor(appearance: navBarAppearance, traits: traits)

        compactAppearance = appearance
        standardAppearance = appearance
    }

    func configureLargeAppearance(navBar: NavBar, traits: UITraitCollection) {
        guard navBar.titleDisplayMode == .large else {
            return
        }

        let largeAppearance = UINavigationBarAppearance()
        largeAppearance.configureFonts(navBar: navBar)

        let navBarAppearance = navBar.appearance
        let navBarAlternateAppearance = navBar.alternateAppearance

        largeAppearance.configureBackground(background: navBarAppearance.background, traits: traits)
        largeAppearance.configureButtonColor(appearance: navBarAppearance, traits: traits)
        largeAppearance.configureTitleColor(appearance: navBarAlternateAppearance ?? navBarAppearance, traits: traits)
        largeAppearance.configureLargeTitleColor(appearance: navBarAppearance, traits: traits)
        scrollEdgeAppearance = largeAppearance

        if let alternateAppearance = navBarAlternateAppearance {
            let inlineAppearance = UINavigationBarAppearance()
            inlineAppearance.configureFonts(navBar: navBar)
            inlineAppearance.configureBackground(background: alternateAppearance.background, traits: traits)
            inlineAppearance.configureButtonColor(appearance: alternateAppearance, traits: traits)
            inlineAppearance.configureTitleColor(appearance: alternateAppearance, traits: traits)
            inlineAppearance.configureLargeTitleColor(appearance: navBar.appearance, traits: traits)

            standardAppearance = inlineAppearance
            compactAppearance = inlineAppearance
        } else {
            standardAppearance = largeAppearance
            compactAppearance = largeAppearance
        }
    }
}

@available(iOS 13.0, *)
private extension UINavigationBarAppearance {
    func configureFonts(navBar: NavBar) {
        titleTextAttributes[.font] = navBar.titleFont.uikitFont
        largeTitleTextAttributes[.font] = navBar.largeTitleFont.uikitFont
        buttonAppearance.normal.titleTextAttributes[.font] = navBar.buttonFont.uikitFont
    }

    func configureBackground(background: NavBar.Background, traits: UITraitCollection) {
        backgroundEffect = background.blurEffect
            ? UIBlurEffect(style: .systemChromeMaterial)
            : nil

        backgroundColor = background.fillColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )

        shadowColor = background.shadowColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )
    }

    func configureButtonColor(appearance: NavBar.Appearance, traits: UITraitCollection) {
        buttonAppearance.normal.titleTextAttributes[.foregroundColor] = appearance.buttonColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )
    }

    func configureTitleColor(appearance: NavBar.Appearance, traits: UITraitCollection) {
        titleTextAttributes[.foregroundColor] = appearance.titleColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )
    }

    func configureLargeTitleColor(appearance: NavBar.Appearance, traits: UITraitCollection  ) {
        largeTitleTextAttributes[.foregroundColor] = appearance.titleColor.uikitUIColor(
            colorScheme: traits.colorScheme,
            colorSchemeContrast: traits.colorSchemeContrast
        )
    }
}

@available(iOS 13.0, *)
private extension UIBarButtonItem {
    private struct AssociatedObject {
        static var key = "app.judo.UIBarButtonItem.onTap"
    }

    private var onTap: () -> Void {
        get {
            objc_getAssociatedObject(self, &AssociatedObject.key) as! () -> Void
        }

        set {
            objc_setAssociatedObject(self, &AssociatedObject.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    convenience init(navBarButton: NavBarButton, stringTable: StringTable, data: JSONObject?, userInfo: UserInfo, onTap: @escaping () -> Void) {
        switch navBarButton.style {
        case .close:
            self.init(
                barButtonSystemItem: .close,
                target: nil,
                action: nil
            )
        case .done:
            self.init(
                barButtonSystemItem: .done,
                target: nil,
                action: nil
            )
        case .custom:
            if let icon = navBarButton.icon {
                self.init(
                    image: UIImage(systemName: icon.symbolName),
                    style: .plain,
                    target: nil,
                    action: nil
                )
            } else {
                self.init(
                    title: navBarButton.title.flatMap { stringTable.resolve(key: $0).evaluatingExpressions(data: data, userInfo: userInfo) },
                    style: .plain,
                    target: nil,
                    action: nil
                )
            }
        }

        target = self
        action = #selector(buttonPressed)

        self.onTap = onTap
    }

    @objc private func buttonPressed(_ sender: Any) {
        onTap()
    }
}

// MARK: - UITraitCollection

@available(iOS 13.0, *)
extension UITraitCollection {
    var colorScheme: ColorScheme {
        userInterfaceStyle == .dark ? .dark : .light
    }

    var colorSchemeContrast: ColorSchemeContrast {
        accessibilityContrast == .high ? .increased : .standard
    }
}
