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
struct ActionModifier: ViewModifier {
    var layer: Layer
    
    @Environment(\.experience) private var experience
    @Environment(\.screen) private var screen
    @Environment(\.presentAction) private var presentAction
    @Environment(\.showAction) private var showAction
    @Environment(\.experienceViewController) private var experienceViewController
    @Environment(\.screenViewController) private var screenViewController
    @Environment(\.data) private var data
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    @Environment(\.authorize) private var authorize
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let action = layer.action, let experience = experience, let screen = screen, let experienceViewController = experienceViewController, let screenViewController = screenViewController {
            Button {
                action.handle(experience: experience, node: layer, screen: screen, data: data, urlParameters: urlParameters, userInfo: userInfo, authorize: authorize, experienceViewController: experienceViewController, screenViewController: screenViewController)
            } label: {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}
 
