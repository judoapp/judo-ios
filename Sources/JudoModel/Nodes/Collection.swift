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
public final class Collection: Layer {
    public struct Filter: Decodable {
        public enum Predicate: String, Decodable {
            case equals
            case doesNotEqual
            case isGreaterThan
            case isLessThan
            case isSet
            case isNotSet
            case isTrue
            case isFalse
        }
        
        public var dataKey: String
        public var predicate: Predicate
        public var value: Any?
        
        public init(dataKey: String, predicate: Predicate, value: Any? = nil) {
            self.dataKey = dataKey
            self.predicate = predicate
            self.value = value
        }
        
        // Decodable
        
        private enum CodingKeys: String, CodingKey {
            case dataKey
            case predicate
            case value
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dataKey = try container.decode(String.self, forKey: .dataKey)
            predicate = try container.decode(Predicate.self, forKey: .predicate)
            
            if let value = try? container.decode(String.self, forKey: .value) {
                self.value = value
            } else if let value = try? container.decode(Double.self, forKey: .value) {
                self.value = value
            } else if let value = try? container.decode(Bool.self, forKey: .value) {
                self.value = value
            } else if let value = try? container.decode(Date.self, forKey: .value) {
                self.value = value
            }
        }
    }
    
    public struct SortDescriptor: Decodable {
        public var dataKey: String
        public var ascending: Bool
        
        public init(dataKey: String, ascending: Bool = true) {
            self.dataKey = dataKey
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
    
    public let dataKey: String
    public let filters: [Filter]
    public let sortDescriptors: [SortDescriptor]
    public let limit: Limit?
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil, dataKey: String, filters: [Filter] = [], sortDescriptors: [SortDescriptor] = [], limit: Limit? = nil) {
        self.dataKey = dataKey
        self.filters = filters
        self.sortDescriptors = sortDescriptors
        self.limit = limit
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility, metadata: metadata)
    }
    
    // MARK: Decodable

    private enum CodingKeys: String, CodingKey {
        case dataKey
        case filters
        case sortDescriptors
        case limit
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataKey = try container.decode(String.self, forKey: .dataKey)
        filters = try container.decode([Filter].self, forKey: .filters)
        sortDescriptors = try container.decode([SortDescriptor].self, forKey: .sortDescriptors)
        limit = try container.decodeIfPresent(Limit.self, forKey: .limit)
        try super.init(from: decoder)
    }
}
