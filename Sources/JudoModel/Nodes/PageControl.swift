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
import Foundation

public final class PageControl: Layer {
    /// The carousel node this Page Control is associated with.
    public var carousel: Carousel?
    /// The style of indicator bullets.
    public let style: PageControl.Style
    /// If true, and the associated Carousel lacks more than one page,
    /// hides the page control.
    public let hidesForSinglePage: Bool
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, carousel: Carousel? = nil, style: PageControl.Style, hidesForSinglePage: Bool) {
        self.carousel = carousel
        self.style = style
        self.hidesForSinglePage = hidesForSinglePage
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }
        
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case style
        case hidesForSinglePage
        case carouselID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        style = try container.decode(PageControl.Style.self, forKey: .style)
        hidesForSinglePage = try container.decode(Bool.self, forKey: .hidesForSinglePage)

        try super.init(from: decoder)

        if container.contains(.carouselID) {
            let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
            let carouselID = try container.decode(Node.ID.self, forKey: .carouselID)
            coordinator.registerOneToOneRelationship(nodeID: carouselID, to: self, keyPath: \.carousel)
        }
    }
}

public extension PageControl {
    enum Style: Decodable {
        case `default`
        case light
        case dark
        case inverted
        case custom(normalColor: ColorVariants, currentColor: ColorVariants)
        case image(normalImage: Image, normalColor: ColorVariants, currentImage: Image, currentColor: ColorVariants)

        // MARK: Codable

        private enum CodingKeys: String, CodingKey {
            case typeName = "__typeName"
            case normalColor
            case currentColor
            case normalImage
            case currentImage
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typeName = try container.decode(String.self, forKey: .typeName)
            switch typeName {
            case "DefaultPageControlStyle":
                self = .default
            case "LightPageControlStyle":
                self = .light
            case "DarkPageControlStyle":
                self = .dark
            case "InvertedPageControlStyle":
                self = .inverted
            case "CustomPageControlStyle":
                let normalColor = try container.decode(ColorVariants.self, forKey: .normalColor)
                let currentColor = try container.decode(ColorVariants.self, forKey: .currentColor)
                self = .custom(normalColor: normalColor, currentColor: currentColor)
            case "ImagePageControlStyle":
                let normalColor = try container.decode(ColorVariants.self, forKey: .normalColor)
                let currentColor = try container.decode(ColorVariants.self, forKey: .currentColor)
                let normalImage = try container.decode(Image.self, forKey: .normalImage)
                let currentImage = try container.decode(Image.self, forKey: .currentImage)
                self = .image(normalImage: normalImage, normalColor: normalColor, currentImage: currentImage, currentColor: currentColor)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .typeName,
                    in: container,
                    debugDescription: "Invalid value: \(typeName)"
                )
            }
        }
    }
}
