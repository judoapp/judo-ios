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

public class Node: Decodable, Identifiable {
    /// A UUID for this node.
    public let id: String

    /// The name of the of the node.
    public let name: String?
    public private(set) var parent: Node?
    /// An array of node that are children of this node.
    public private(set) var children = [Node]()
        
    // Layout
    public let ignoresSafeArea: Set<Edge>?
    public let aspectRatio: CGFloat?
    public let padding: Padding?
    public let frame: Frame?
    public let layoutPriority: CGFloat?
    public let offset: CGPoint?
    
    // Appearance
    public let shadow: Shadow?
    public let opacity: CGFloat?
    
    // Layering
    public let background: Background?
    public let overlay: Overlay?
    public let mask: Node?
    
    // Interaction
    public let action: Action?
    public let accessibility: Accessibility?
    
    // Metadata
    public let metadata: Metadata?
    
    public init(id: String = UUID().uuidString, name: String?, parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Background? = nil, overlay: Overlay? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, metadata: Metadata? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
        self.children = children
        self.ignoresSafeArea = ignoresSafeArea
        self.aspectRatio = aspectRatio
        self.padding = padding
        self.frame = frame
        self.layoutPriority = layoutPriority
        self.offset = offset
        self.shadow = shadow
        self.opacity = opacity
        self.background = background
        self.overlay = overlay
        self.mask = mask
        self.action = action
        self.accessibility = accessibility
        self.metadata = metadata
        
        self.children.forEach { $0.parent = self }
    }
    
    // MARK: Decodable

    static var typeName: String {
        String(describing: Self.self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case id
        case name
        case childIDs
        case isSelected
        case isCollapsed
        case ignoresSafeArea
        case aspectRatio
        case padding
        case frame
        case layoutPriority
        case offset
        case shadow
        case opacity
        case background
        case overlay
        case mask
        case action
        case accessibility
        case metadata
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Node.ID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
        
        // Layout
        if let edgeValueSet = try container.decodeIfPresent(Set<Edge>.self, forKey: .ignoresSafeArea) {
            ignoresSafeArea = Set(edgeValueSet.compactMap{ $0 })
        } else {
            ignoresSafeArea = nil
        }
        
        aspectRatio = try container.decodeIfPresent(CGFloat.self, forKey: .aspectRatio)
        padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
        frame = try container.decodeIfPresent(Frame.self, forKey: .frame)
        layoutPriority = try container.decodeIfPresent(CGFloat.self, forKey: .layoutPriority)
        offset = try container.decodeIfPresent(CGPoint.self, forKey: .offset)
        
        // Appearance
        shadow = try container.decodeIfPresent(Shadow.self, forKey: .shadow)
        opacity = try container.decodeIfPresent(CGFloat.self, forKey: .opacity)
        
        // Layering
        background = try container.decodeIfPresent(Background.self, forKey: .background)
        overlay = try container.decodeIfPresent(Overlay.self, forKey: .overlay)
        mask = try container.decodeNodeIfPresent(forKey: .mask)
        
        // Interaction
        action = try container.decodeIfPresent(Action.self, forKey: .action)
        accessibility = try container.decodeIfPresent(Accessibility.self, forKey: .accessibility)
        metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata)

        if container.contains(.childIDs) {
            coordinator.registerOneToManyRelationship(
                nodeIDs: try container.decode([Node.ID].self, forKey: .childIDs),
                to: self,
                keyPath: \.children,
                inverseKeyPath: \.parent
            )
        }
    }
}

// MARK: Sequence

@available(iOS 13.0, *)
extension Sequence where Element: Node {
    
    #if os(macOS)
    /// Returns a collection of nodes which have the given traits.
    func filter(_ traits: Traits) -> [Element] {
        filter { $0.traits.contains(traits) }
    }
    #endif
    
    /// Traverses the node graph, starting with the node's children, until it finds a node that matches the
    /// supplied predicate, from the top of the z-order.
    func highest(where predicate: (Node) -> Bool) -> Node? {
        reduce(nil) { result, node in
            guard result == nil else {
                return result
            }
            
            if predicate(node) {
                return node
            }
            
            return node.children.highest(where: predicate)
        }
    }
    
    /// Traverses the node graph, starting with the node's children, until it finds a node that matches the
    /// supplied predicate, from the bottom of the z-order.
    func lowest(where predicate: (Node) -> Bool) -> Node? {
        reversed().reduce(nil) { result, node in
            guard result == nil else {
                return result
            }
            
            if predicate(node) {
                return node
            }
            
            return node.children.lowest(where: predicate)
        }
    }
    
    func traverse(_ block: (Node) -> Void) {
        forEach { node in
            block(node)
            node.children.traverse(block)
        }
    }

    func flatten() -> [Node] {
        flatMap { node -> [Node] in
            [node] + node.children.flatten()
        }
    }
}

