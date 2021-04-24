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

public struct GradientVariants: Hashable, Decodable {
    /// The default gradient to use if there is no match for the device's mode. The gradient for devices with light mode enabled.
    public let `default`: JudoModel.Gradient
    /// The gradient to use when the device has high contrast enabled.
    public let darkMode: JudoModel.Gradient?
    /// The gradient to use when the device has high contrast enabled.
    public let highContrast: JudoModel.Gradient?
    /// The gradient to use when the device has dark mode and high contrast enabled.
    public let darkModeHighContrast: JudoModel.Gradient?
    
    public init(default: Gradient, darkMode: Gradient?, highContrast: Gradient?, darkModeHighContrast: Gradient?) {
        self.default = `default`
        self.darkMode = darkMode
        self.highContrast = highContrast
        self.darkModeHighContrast = darkModeHighContrast
    }
}
