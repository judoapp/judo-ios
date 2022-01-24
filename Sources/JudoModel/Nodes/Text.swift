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

import CoreGraphics
import SwiftUI

@available(iOS 13.0, *)
public final class Text: Layer {
    public enum Transform: String, Codable {
        case uppercase
        case lowercase
    }
    /// The text content to render.
    public let text: String
    public let font: Font
    public let textColor: ColorVariants
    /// The alignment behavior of the Text.
    public let textAlignment: SwiftUI.TextAlignment
    public let lineLimit: Int?
    public let transform: Transform?
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, text: String, font: Font, textColor: ColorVariants, textAlignment: TextAlignment, lineLimit: Int?, transform: Text.Transform?) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.lineLimit = lineLimit
        self.transform = transform
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }

    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case text
        case font
        case textColor
        case textAlignment
        case lineLimit
        case transform
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        font = try container.decode(Font.self, forKey: .font)
        textColor = try container.decode(ColorVariants.self, forKey: .textColor)
        textAlignment = try container.decode(TextAlignmentValue.self, forKey: .textAlignment).textAlignment
        lineLimit = try container.decodeIfPresent(Int.self, forKey: .lineLimit)
        transform = try container.decodeIfPresent(Transform.self, forKey: .transform)
        try super.init(from: decoder)
    }
}
