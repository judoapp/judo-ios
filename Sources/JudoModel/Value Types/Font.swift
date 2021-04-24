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
import CoreGraphics
import SwiftUI

public typealias FontFamily = String

public typealias FontName = String

@available(iOS 13.0, *)
public enum Font: Decodable, Hashable {

    public enum Emphasis: String, Hashable, Decodable {
        case bold
        case italic
    }

    /// A system font with a given semantic style that responds to the Dynamic Type system on iOS and the equivalent on Android.
    case dynamic(textStyle: SwiftUI.Font.TextStyle, emphases: Set<Font.Emphasis>)

    /// A system font with a fixed size and weight.
    case fixed(size: CGFloat, weight: SwiftUI.Font.Weight)

    /// A custom font which uses the supplied `FontName` and given `size`.
    case custom(fontName: FontName, size: CGFloat, isDynamic: Bool)

    static let largeTitle = Font.dynamic(textStyle: .largeTitle, emphases: [])
    static let title = Font.dynamic(textStyle: .title, emphases: [])
    @available(iOS 14.0, *)
    static let title2 = Font.dynamic(textStyle: .title2, emphases: [])
    @available(iOS 14.0, *)
    static let title3 = Font.dynamic(textStyle: .title3, emphases: [])
    static let headline = Font.dynamic(textStyle: .headline, emphases: [])
    static let body = Font.dynamic(textStyle: .body, emphases: [])
    static let callout = Font.dynamic(textStyle: .callout, emphases: [])
    static let subheadline = Font.dynamic(textStyle: .subheadline, emphases: [])
    static let footnote = Font.dynamic(textStyle: .footnote, emphases: [])
    static let caption = Font.dynamic(textStyle: .caption, emphases: [])
    @available(iOS 14.0, *)
    static let caption2 = Font.dynamic(textStyle: .caption2, emphases: [])

    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case textStyle
        case emphases
        case size
        case weight
        case isDynamic
        case fontName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .typeName)
        switch typeName {
        case "DynamicFont":
            let textStyle = try container.decode(SwiftUI.Font.TextStyle.self, forKey: .textStyle)
            let emphases = try container.decode(Set<Font.Emphasis>.self, forKey: .emphases)
            self = .dynamic(textStyle: textStyle, emphases: emphases)
        case "FixedFont":
            let size = try container.decode(CGFloat.self, forKey: .size)
            let weight = try container.decode(SwiftUI.Font.Weight.self, forKey: .weight)
            self = .fixed(size: size, weight: weight)
        case "CustomFont":
            let fontName = try container.decode(FontName.self, forKey: .fontName)
            let size = try container.decode(CGFloat.self, forKey: .size)
            let isDynamic = try container.decode(Bool.self, forKey: .isDynamic)
            self = .custom(fontName: fontName, size: size, isDynamic: isDynamic)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .typeName,
                in: container,
                debugDescription: "Invalid value: \(typeName)"
            )
        }
    }
}
