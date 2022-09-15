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

import os.log
import SwiftUI

// MARK: Axis

public enum Axis: String, Decodable {
    case horizontal
    case vertical

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.Axis {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

// MARK: TextAlignment

public enum TextAlignment: String, Decodable {
    case center
    case leading
    case trailing

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.TextAlignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

// MARK: HorizontalAlignment

public enum HorizontalAlignment: String, Decodable {
    case center
    case leading
    case trailing

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.HorizontalAlignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

// MARK: VerticalAlignment

public enum VerticalAlignment: String, Decodable {
    case bottom
    case center
    case firstTextBaseline = "baseline"
    case top

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.VerticalAlignment {
        switch self {
        case .bottom:
            return .bottom
        case .center:
            return .center
        case .firstTextBaseline:
            return .firstTextBaseline
        case .top:
            return .top
        }
    }
}


// MARK: Alignment

public enum Alignment: String, Decodable {
    case bottom
    case bottomLeading
    case bottomTrailing
    case center
    case leading
    case top
    case topLeading
    case topTrailing
    case trailing


    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.Alignment {
        switch self {
        case .bottom:
            return .bottom
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        case .center:
            return .center
        case .leading:
            return .leading
        case .top:
            return .top
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .trailing:
            return .trailing
        }
    }
}

// MARK: Edge

public enum Edge: String, Decodable { // does this require Identifiable, Hashable conformances?
    case top
    case leading
    case bottom
    case trailing

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.Edge {
        switch self {
        case .top:
            return .top
        case .leading:
            return .leading
        case .bottom:
            return .bottom
        case .trailing:
            return .trailing
        }
    }
}

// MARK: FontTextStyle

public enum FontTextStyle: String, Decodable {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.Font.TextStyle {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title
        case .title2:
            if #available(iOS 14.0, *) {
                return .title2
            } else {
                return .title
            }
        case .title3:
            if #available(iOS 14.0, *) {
                return .title3
            } else {
                return .title
            }
        case .headline:
            return .headline
        case .body:
            return .body
        case .callout:
            return .callout
        case .subheadline:
            return .subheadline
        case .footnote:
            return .footnote
        case .caption:
            return .caption
        case .caption2:
            if #available(iOS 14.0, *) {
                return .caption2
            } else {
                return .caption
            }
        }
    }
}

// MARK: FontWeight

public enum FontWeight: String, Decodable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    @available(iOS 13.0, *)
    public var swiftUIValue: SwiftUI.Font.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        }
    }
}
