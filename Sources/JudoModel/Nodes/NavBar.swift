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

public final class NavBar: Node {
    public enum TitleDisplayMode: String, Decodable {
        case inline
        case large
    }
    
    public struct Background: Decodable {
        public let fillColor: ColorVariants
        public let shadowColor: ColorVariants
        public let blurEffect: Bool
        
        public init(fillColor: ColorVariants, shadowColor: ColorVariants, blurEffect: Bool) {
            self.fillColor = fillColor
            self.shadowColor = shadowColor
            self.blurEffect = blurEffect
        }
    }
    
    public struct Appearance: Decodable {
        public let titleColor: ColorVariants
        public let buttonColor: ColorVariants
        public let background: Background
        
        public init(titleColor: ColorVariants, buttonColor: ColorVariants, background: Background) {
            self.titleColor = titleColor
            self.buttonColor = buttonColor
            self.background = background
        }
    }
    
    public let title: String
    public let titleDisplayMode: TitleDisplayMode
    public let hidesBackButton: Bool
    public let titleFont: Font
    public let largeTitleFont: Font
    public let buttonFont: Font
    public let appearance: Appearance
    public let alternateAppearance: Appearance?
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: JudoModel.Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, title: String, titleDisplayMode: TitleDisplayMode, hidesBackButton: Bool, titleFont: Font, largeTitleFont: Font, buttonFont: Font, appearance: Appearance, alternateAppearance: Appearance?) {
        
        self.title = title
        self.titleDisplayMode = titleDisplayMode
        self.hidesBackButton = hidesBackButton
        self.titleFont = titleFont
        self.largeTitleFont = largeTitleFont
        self.buttonFont = buttonFont
        self.appearance = appearance
        self.alternateAppearance = alternateAppearance
        
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case title
        case titleDisplayMode
        case hidesBackButton
        case titleFont
        case largeTitleFont
        case buttonFont
        case appearance
        case alternateAppearance
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        titleDisplayMode = try container.decode(TitleDisplayMode.self, forKey: .titleDisplayMode)
        hidesBackButton = try container.decode(Bool.self, forKey: .hidesBackButton)
        titleFont = try container.decode(Font.self, forKey: .titleFont)
        largeTitleFont = try container.decode(Font.self, forKey: .largeTitleFont)
        buttonFont = try container.decode(Font.self, forKey: .buttonFont)
        appearance = try container.decode(Appearance.self, forKey: .appearance)
        alternateAppearance = try container.decodeIfPresent(Appearance.self, forKey: .alternateAppearance)
        try super.init(from: decoder)
    }
}
