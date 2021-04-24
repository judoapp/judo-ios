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
import os.log

// MARK: Axis

@available(iOS 13.0, *)
extension Axis: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "horizontal":
            self = .horizontal
        case "vertical":
            self = .vertical
        default:
            self = .vertical
            judo_log(.error, "Unsupported axis: %@", value)
        }
    }
}

@available(iOS 13.0, *)
extension Axis: Identifiable {
    public var id: Int8 {
        rawValue
    }
}

// MARK: ContentSizeCategory

@available(iOS 13.0, *)
extension ContentSizeCategory: Decodable {
    static let `default`: ContentSizeCategory = .large
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
            case "accessibilityExtraExtraExtraLarge":
                self = .accessibilityExtraExtraExtraLarge
            case "accessibilityExtraExtraLarge":
                self = .accessibilityExtraExtraLarge
            case "accessibilityExtraLarge":
                self = .accessibilityExtraLarge
            case "accessibilityLarge":
                self = .accessibilityLarge
            case "accessibilityMedium":
                self = .accessibilityMedium
            case "extraExtraExtraLarge":
                self = .extraExtraExtraLarge
            case "extraExtraLarge":
                self = .extraExtraLarge
            case "extraLarge":
                self = .extraLarge
            case "extraSmall":
                self = .extraSmall
            case "large":
                self = .large
            case "medium":
                self = .medium
            case "small":
                self = .small
            default:
                judo_log(.error, "Unsupported content size category: %@", rawValue)
                self = .medium
        }
    }
}


// MARK: TextAlignment

@available(iOS 13.0, *)
extension TextAlignment: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "center":
            self = .center
        case "leading":
            self = .leading
        case "trailing":
            self = .trailing
        default:
            self = .center
            judo_log(.error, "Unsupported text alignment: %@", value)
        }
    }
}

@available(iOS 13.0, *)
extension TextAlignment: Identifiable {
    public var id: Int {
        hashValue
    }
}

// MARK: HorizontalAlignment

@available(iOS 13.0, *)
extension HorizontalAlignment: CaseIterable {
    public static var allCases: [HorizontalAlignment] {
        [.leading, .center, .trailing]
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "center":
            self = .center
        case "leading":
            self = .leading
        case "trailing":
            self = .trailing
        default:
            judo_log(.error, "Unsupported horizontal alignment: %@", rawValue)
            self = .center
        }
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment: Identifiable {
    public var id: String {
        rawValue
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment {
    public var rawValue: String {
        switch self {
        case .center:
            return "center"
        case .leading:
            return "leading"
        case .trailing:
            return "trailing"
        default:
            assertionFailure()
            return "center"
        }
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment {
    var symbolName: String {
        switch self {
        case .leading:
            return "arrow.left.to.line"
        case .center:
            return  "text.aligncenter"
        case .trailing:
            return "arrow.right.to.line"
        default:
            assertionFailure()
            return "text.aligncenter"
        }
    }
}

// MARK: VerticalAlignment

@available(iOS 13.0, *)
extension VerticalAlignment: CaseIterable {
    public static var allCases: [VerticalAlignment] {
        [.top, .center, .bottom, .firstTextBaseline]
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "bottom":
            self = .bottom
        case "center":
            self = .center
        case "baseline":
            self = .firstTextBaseline
        case "top":
            self = .top
        default:
            judo_log(.error, "Unsupported vertical alignment: %@", rawValue)
            self = .bottom
        }
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment: Identifiable {
    public var id: String {
        rawValue
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment {
    public var rawValue: String {
        switch self {
        case .bottom:
            return "bottom"
        case .center:
            return "center"
        case .firstTextBaseline:
            return "baseline"
        case .top:
            return "top"
        default:
            assertionFailure()
            return "center"
        }
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment {
    var symbolName: String {
        switch self {
        case .top:
            return "arrow.up.to.line"
        case .center:
            return "text.aligncenter"
        case .bottom:
            return "arrow.down.to.line"
        case .firstTextBaseline:
            return "textformat.abc.dottedunderline"
        default:
            assertionFailure()
            return "text.aligncenter"
        }
    }
}

// MARK: Alignment

@available(iOS 13.0, *)
extension Alignment: CaseIterable {
    public static var allCases: [Alignment] {
        [
            .bottom,
            .bottomLeading,
            .bottomTrailing,
            .center,
            .leading,
            .top,
            .topLeading,
            .topTrailing,
            .trailing
        ]
    }
}

@available(iOS 13.0, *)
extension Alignment: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "bottom":
            self = .bottom
        case "bottomLeading":
            self = .bottomLeading
        case "bottomTrailing":
            self = .bottomTrailing
        case "center":
            self = .center
        case "leading":
            self = .leading
        case "top":
            self = .top
        case "topLeading":
            self = .topLeading
        case "topTrailing":
            self = .topTrailing
        case "trailing":
            self = .trailing
        default:
            judo_log(.error, "Unsupported alignment: %@", rawValue)
            self = .center
        }
    }
}

@available(iOS 13.0, *)
extension Alignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

@available(iOS 13.0, *)
extension Alignment: Identifiable {
    public var id: String {
        rawValue
    }
}

@available(iOS 13.0, *)
extension Alignment {
    public var rawValue: String {
        switch self {
        case .bottom:
            return "bottom"
        case .bottomLeading:
            return "bottomLeading"
        case .bottomTrailing:
            return "bottomTrailing"
        case .center:
            return "center"
        case .leading:
            return "leading"
        case .top:
            return "top"
        case .topLeading:
            return "topLeading"
        case .topTrailing:
            return "topTrailing"
        case .trailing:
            return "trailing"
        default:
            assertionFailure()
            return "center"
        }
    }
}

// MARK: Edge

@available(iOS 13.0, *)
extension Edge: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "top":
            self = .top
        case "leading":
            self = .leading
        case "bottom":
            self = .bottom
        case "trailing":
            self = .trailing
        default:
            self = .leading
            judo_log(.error, "Unsupported edge: %@", rawValue)
        }
    }
}

// MARK: SwiftUI.Font.TextStyle

@available(iOS 13.0, *)
@available(iOS 13.0, *)
extension SwiftUI.Font.TextStyle: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value {
        case "largeTitle":
            self = .largeTitle
        case "title":
            self = .title
        case "title2":
            if #available(iOS 14.0, *) {
                self = .title2
            } else {
                self = .title
            }
        case "title3":
            if #available(iOS 14.0, *) {
                self = .title3
            } else {
                self = .title
            }
        case "headline":
            self = .headline
        case "body":
            self = .body
        case "callout":
            self = .callout
        case "subheadline":
            self = .subheadline
        case "footnote":
            self = .footnote
        case "caption":
            self = .caption
        case "caption2":
            if #available(iOS 14.0, *) {
                self = .caption2
            } else {
                self = .caption
            }
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value: \(value.self)"
            )
        }
    }
}

// MARK: SwiftUI.Font.Weight

@available(iOS 13.0, *)
@available(iOS 13.0, *)
extension SwiftUI.Font.Weight: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value {
        case "ultraLight":
            self = .ultraLight
        case "thin":
            self = .thin
        case "light":
            self = .light
        case "regular":
            self = .regular
        case "medium":
            self = .medium
        case "semibold":
            self = .semibold
        case "bold":
            self = .bold
        case "heavy":
            self = .heavy
        case "black":
            self = .black
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value: \(value.self)"
            )
        }
    }
}
