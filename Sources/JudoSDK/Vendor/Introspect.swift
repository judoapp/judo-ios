// Copyright 2019 Timber Software
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI

@available(iOS 13.0, *)
extension View {
    func introspectScrollView(customize: @escaping (UIScrollView) -> ()) -> some View {
        if #available(iOS 14.0, tvOS 14.0, macOS 11.0, *) {
            return introspect(selector: TargetViewSelector.ancestorOrSiblingOfType, customize: customize)
        } else {
            return introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
        }
    }
}

// MARK: File Private

@available(iOS 13.0, *)
private extension View {
    func introspect<TargetView: UIView>(selector: @escaping (IntrospectionUIView) -> TargetView?, customize: @escaping (TargetView) -> ()) -> some View {
        inject(UIKitIntrospectionView(
            selector: selector,
            customize: customize
        ))
    }
    
    func inject<SomeView>(_ view: SomeView) -> some View where SomeView: View {
        overlay(view.frame(width: 0, height: 0))
    }
}

@available(iOS 13.0, *)
private class IntrospectionUIView: UIView {
    required init() {
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
private struct UIKitIntrospectionView<TargetViewType: UIView>: UIViewRepresentable {
    let selector: (IntrospectionUIView) -> TargetViewType?
    let customize: (TargetViewType) -> Void
    
    init(
        selector: @escaping (IntrospectionUIView) -> TargetViewType?,
        customize: @escaping (TargetViewType) -> Void
    ) {
        self.selector = selector
        self.customize = customize
    }
    
    func makeUIView(context: UIViewRepresentableContext<UIKitIntrospectionView>) -> IntrospectionUIView {
        let view = IntrospectionUIView()
        view.accessibilityLabel = "IntrospectionUIView<\(TargetViewType.self)>"
        return view
    }

    func updateUIView(
        _ uiView: IntrospectionUIView,
        context: UIViewRepresentableContext<UIKitIntrospectionView>
    ) {
        DispatchQueue.main.async {
            guard let targetView = self.selector(uiView) else {
                return
            }
            self.customize(targetView)
        }
    }
}

private enum Introspect {
    static func findChild<AnyViewType: UIView>(ofType type: AnyViewType.Type, in root: UIView) -> AnyViewType? {
        for subview in root.subviews {
            if let typed = subview as? AnyViewType {
                return typed
            } else if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }
        
        return nil
    }

    static func previousSibling<AnyViewType: UIView>(containing type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        guard let superview = entry.superview,
              let entryIndex = superview.subviews.firstIndex(of: entry),
              entryIndex > 0 else {
            return nil
        }

        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }

        return nil
    }

    static func previousSibling<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        guard let superview = entry.superview,
              let entryIndex = superview.subviews.firstIndex(of: entry),
              entryIndex > 0 else {
            return nil
        }

        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = subview as? AnyViewType {
                return typed
            }
        }

        return nil
    }

    static func findAncestor<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        var superview = entry.superview
        while let s = superview {
            if let typed = s as? AnyViewType {
                return typed
            }
            
            superview = s.superview
        }
        
        return nil
    }

    static func findViewHost(from entry: UIView) -> UIView? {
        var superview = entry.superview
        while let s = superview {
            if NSStringFromClass(type(of: s)).contains("ViewHost") {
                return s
            }
            
            superview = s.superview
        }
        
        return nil
    }
}

private enum TargetViewSelector {
    static func siblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = Introspect.findViewHost(from: entry) else {
            return nil
        }
        
        return Introspect.previousSibling(containing: TargetView.self, from: viewHost)
    }
    
    static func siblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = Introspect.findViewHost(from: entry) else {
            return nil
        }
        
        return Introspect.previousSibling(ofType: TargetView.self, from: viewHost)
    }
    
    static func ancestorOrSiblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = Introspect.findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        
        return siblingContaining(from: entry)
    }

    static func ancestorOrSiblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = Introspect.findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        
        return siblingOfType(from: entry)
    }
}
