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
import SwiftUI
import JudoModel

@available(iOS 13.0, *)
extension ColorVariants {
    func uikitUIColor(colorScheme: ColorScheme, colorSchemeContrast: ColorSchemeContrast) -> UIColor? {
        if let systemColor = systemName {
            return UIColor.named(systemColor)
        } else if let highContrast = highContrast, colorScheme != .dark, colorSchemeContrast == .increased {
            return highContrast.uiColor
        } else if let darkModeHighContrast = darkModeHighContrast, colorScheme == .dark, colorSchemeContrast == .increased {
            return darkModeHighContrast.uiColor
        } else if let darkMode = darkMode, colorScheme == .dark {
            return darkMode.uiColor
        } else if let `default` = `default` {
            return `default`.uiColor
        } else {
            return nil
        }
    }
}
