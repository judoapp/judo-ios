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
import UIKit
import JudoModel

@available(iOS 13.0, *)
struct FontModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var uiFont: SwiftUI.Font

    var font: JudoModel.Font

    init(font: JudoModel.Font) {
        self.font = font
        self._uiFont = .init(initialValue: getUIFont(for: font))
    }

    func body(content: Content) -> some View {
        content
            .font(uiFont)
            .onReceive(NotificationCenter.default.publisher(for: Judo.didRegisterCustomFontNotification)) { _ in
                uiFont = getUIFont(for: font)
            }
    }
}

@available(iOS 13.0, *)
private func getUIFont(for font: JudoModel.Font) -> SwiftUI.Font {
    if let uifont = font.uikitFont {
        return SwiftUI.Font(uifont)
    }

    return .body
}


