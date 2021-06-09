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

@available(iOS 13.0, *)
struct TextView: View {
    @Environment(\.data) private var data
    @Environment(\.stringTable) private var stringTable
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    
    var text: JudoModel.Text
    
    var body: some View {
        let textString = stringTable.resolve(key: text.text)
        
        if let textValue = textString.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo) {
            RealizeColor(self.text.textColor) { textColor in
                SwiftUI.Text(transformed(textValue))
                    .modifier(
                        FontModifier(font: self.text.font)
                    )
                    .foregroundColor(textColor)
            }
            .multilineTextAlignment(uiTextAlignment)
            .lineLimit(self.text.lineLimit)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func transformed(_ text: String) -> String {
        switch self.text.transform {
        case .lowercase:
            return text.lowercased()
        case .uppercase:
            return text.uppercased()
        case .none:
            return text
        }
    }
    
    private var uiTextAlignment: SwiftUI.TextAlignment {
        switch text.textAlignment {
        case .center:
            return .center
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}
