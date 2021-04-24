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

import Foundation
import SwiftUI
import JudoModel

// MARK: SwiftUI Value

@available(iOS 13.0, *)
public extension JudoModel.Gradient {
    func swiftUIGradient(startPoint: UnitPoint? = nil, endPoint: UnitPoint? = nil) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(
                stops: stops
                    .sorted { $0.position < $1.position }
                    .map { Gradient.Stop(color: $0.color.swiftUIColor, location: CGFloat($0.position)) }
            ),
            startPoint: startPoint ?? .init(x: from.x, y: from.y),
            endPoint: endPoint ?? .init(x: to.x, y: to.y)
        )
    }
}
