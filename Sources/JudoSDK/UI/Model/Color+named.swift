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

@available(iOS 13.0, *)
extension Color {
    static func named(_ name: String) -> Color {
        guard let color = semanticColor(named: name) ?? standardColor(named: name) else {
            assertionFailure("Invalid color name: \"\(name)\"")
            return .clear
        }
        
        return color
    }
    
    private static func semanticColor(named name: String) -> Color? {
        switch name {
        case "label":
            return Color(.label)
        case "secondaryLabel":
            return Color(.secondaryLabel)
        case "tertiaryLabel":
            return Color(.tertiaryLabel)
        case "quaternaryLabel":
            return Color(.quaternaryLabel)
        case "systemFill":
            return Color(.systemFill)
        case "secondarySystemFill":
            return Color(.secondarySystemFill)
        case "tertiarySystemFill":
            return Color(.tertiarySystemFill)
        case "quaternarySystemFill":
            return Color(.quaternarySystemFill)
        case "placeholderText":
            return Color(.placeholderText)
        case "systemBackground":
            return Color(.systemBackground)
        case "secondarySystemBackground":
            return Color(.secondarySystemBackground)
        case "tertiarySystemBackground":
            return Color(.tertiarySystemBackground)
        case "systemGroupedBackground":
            return Color(.systemGroupedBackground)
        case "secondarySystemGroupedBackground":
            return Color(.secondarySystemGroupedBackground)
        case "tertiarySystemGroupedBackground":
            return Color(.tertiarySystemGroupedBackground)
        case "separator":
            return Color(.separator)
        case "opaqueSeparator":
            return Color(.opaqueSeparator)
        case "link":
            return Color(.link)
        case "darkText":
            return Color(.darkText)
        case "lightText":
            return Color(.lightText)
        case "systemBlue":
            return Color(.systemBlue)
        case "systemGreen":
            return Color(.systemGreen)
        case "systemIndigo":
            return Color(.systemIndigo)
        case "systemOrange":
            return Color(.systemOrange)
        case "systemPink":
            return Color(.systemPink)
        case "systemPurple":
            return Color(.systemPurple)
        case "systemRed":
            return Color(.systemRed)
        case "systemTeal":
            return Color(.systemTeal)
        case "systemYellow":
            return Color(.systemYellow)
        case "systemGray":
            return Color(.systemGray)
        case "systemGray2":
            return Color(.systemGray2)
        case "systemGray3":
            return Color(.systemGray3)
        case "systemGray4":
            return Color(.systemGray4)
        case "systemGray5":
            return Color(.systemGray5)
        case "systemGray6":
            return Color(.systemGray6)
        case "black":
            return .black
        default:
            return nil
        }
    }
    
    private static func standardColor(named name: String) -> Color? {
        switch name {
        case "black":
            return .black
        case "blue":
            return .blue
        case "clear":
            return .clear
        case "gray":
            return .gray
        case "green":
            return .green
        case "orange":
            return .orange
        case "pink":
            return .pink
        case "primary":
            return .primary
        case "purple":
            return .purple
        case "red":
            return .red
        case "secondary":
            return .secondary
        case "white":
            return .white
        case "yellow":
            return .yellow
        default:
            return nil
        }
    }
}
