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

public class Video: Layer {

    public enum ResizingMode: String, Decodable {
        case scaleToFit
        case scaleToFill
    }

    /// Video URL
    public let sourceURL: String

    /// Poster image URL
    public let posterImageURL: String?

    /// Resizing mode
    public let resizingMode: ResizingMode

    /// When true the media player shown in the Judo layer will feature playback/transport controls.
    public let showControls: Bool

    /// When true the video will begin playing when the Screen is displayed.
    public let autoPlay: Bool

    /// When true the video will loop.
    public let looping: Bool

    /// When true audio track is inhibited from playback.
    public let removeAudio: Bool

    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, sourceURL: String, posterImageURL: String?, resizingMode: ResizingMode, showControls: Bool, autoPlay: Bool, looping: Bool, removeAudio: Bool) {
        self.sourceURL = sourceURL
        self.posterImageURL = posterImageURL
        self.resizingMode = resizingMode
        self.showControls = showControls
        self.autoPlay = autoPlay
        self.looping = looping
        self.removeAudio = removeAudio
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }

    private enum CodingKeys: String, CodingKey {
        case sourceURL
        case posterImageURL
        case resizingMode
        case showControls
        case autoPlay
        case looping
        case removeAudio
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        posterImageURL = try container.decodeIfPresent(String.self, forKey: .posterImageURL)
        resizingMode = try container.decode(ResizingMode.self, forKey: .resizingMode)
        showControls = try container.decode(Bool.self, forKey: .showControls)
        autoPlay = try container.decode(Bool.self, forKey: .autoPlay)
        looping = try container.decode(Bool.self, forKey: .looping)
        removeAudio = try container.decode(Bool.self, forKey: .removeAudio)
        try super.init(from: decoder)
    }
}
