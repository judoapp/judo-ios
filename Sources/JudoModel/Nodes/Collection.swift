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

public final class Collection: Layer {
    public struct SortDescriptor: Decodable {
        public var keyPath: String
        public var ascending: Bool
        
        public init(keyPath: String, ascending: Bool = true) {
            self.keyPath = keyPath
            self.ascending = ascending
        }
    }
    
    public struct Limit: Decodable {
        public var show: Int
        public var startAt: Int
        
        public init(show: Int, startAt: Int) {
            self.show = show
            self.startAt = startAt
        }
    }
    
    public let keyPath: String
    public let filters: [Condition]
    public let sortDescriptors: [SortDescriptor]
    public let limit: Limit?
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, keyPath: String, filters: [Condition] = [], sortDescriptors: [SortDescriptor] = [], limit: Limit? = nil) {
        self.keyPath = keyPath
        self.filters = filters
        self.sortDescriptors = sortDescriptors
        self.limit = limit
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }
    
    // MARK: Decodable

    private enum CodingKeys: String, CodingKey {
        case keyPath
        case filters
        case sortDescriptors
        case limit
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyPath = try container.decode(String.self, forKey: .keyPath)
        filters = try container.decode([Condition].self, forKey: .filters)
        sortDescriptors = try container.decode([SortDescriptor].self, forKey: .sortDescriptors)
        limit = try container.decodeIfPresent(Limit.self, forKey: .limit)
        try super.init(from: decoder)
    }
}
