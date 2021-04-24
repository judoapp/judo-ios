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

import SwiftUI
import JudoModel


/// Realize a ColorVariants into a UIColor or SwiftUI.Color.
@available(iOS 13.0, *)
struct RealizeColor<Content, C>: View where Content: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private let colorVariants: ColorVariants
    private let content: (C) -> Content

    init(_ colorVariants: ColorVariants, @ViewBuilder content: @escaping (C) -> Content) where C == SwiftUI.Color {
        self.colorVariants = colorVariants
        self.content = content
    }

    init(_ colorVariants: ColorVariants, @ViewBuilder content: @escaping (C) -> Content) where C == UIColor {
        self.colorVariants = colorVariants
        self.content = content
    }

    var body: some View {
        if C.self == SwiftUI.Color.self {
            content(swiftUIColor() as! C)
        } else if C.self == UIColor.self {
            content(uikitUIColor() as! C)
        }
    }

    private func swiftUIColor() -> SwiftUI.Color {
        if let systemColor = self.colorVariants.systemName {
            return SwiftUI.Color.named(systemColor)
        } else if let highContrast = self.colorVariants.highContrast, colorScheme != .dark, colorSchemeContrast == .increased {
            return highContrast.swiftUIColor
        } else if let darkModeHighContrast = self.colorVariants.darkModeHighContrast, colorScheme == .dark, colorSchemeContrast == .increased {
            return darkModeHighContrast.swiftUIColor
        } else if let darkMode = self.colorVariants.darkMode, colorScheme == .dark {
            return darkMode.swiftUIColor
        } else if let `default` = self.colorVariants.default {
            return `default`.swiftUIColor
        } else {
            return Color(.clear)
        }
    }

    private func uikitUIColor() -> UIColor {
        self.colorVariants.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast) ?? .clear
    }
}
