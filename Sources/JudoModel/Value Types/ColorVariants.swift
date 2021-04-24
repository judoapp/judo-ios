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

public struct ColorVariants: Codable, Hashable {
    /// An iOS system color
    public let systemName: String?
    /// The default color to use if there is no match for the device's mode.
    /// The color to use for when device has light mode enabled.
    public let `default`: JudoModel.Color?
    /// The color to use when the device has high contrast enabled.
    public let highContrast: JudoModel.Color?
    /// The color to use when the device has dark mode enabled.
    public let darkMode: JudoModel.Color?
    /// The color to use when the device has dark mode and high contrast enabled.
    public let darkModeHighContrast: JudoModel.Color?
    
    public init(systemName: String?, default: Color?, highContrast: Color?, darkMode: Color?, darkModeHighContrast: Color?) {
        self.systemName = systemName
        self.default = `default`
        self.highContrast = highContrast
        self.darkMode = darkMode
        self.darkModeHighContrast = darkModeHighContrast
    }

    public static let clear = ColorVariants(systemName: "clear", default: nil, highContrast: nil, darkMode: nil, darkModeHighContrast: nil)
}
