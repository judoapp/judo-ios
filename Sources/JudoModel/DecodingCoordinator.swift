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
import os.log

@available(iOS 13.0, *)
final class DecodingCoordinator {
    private var pendingRelationships = [PendingRelationship]()
    
    func registerOneToOneRelationship<T, U>(
        nodeID: Node.ID,
        to object: T,
        keyPath: ReferenceWritableKeyPath<T, U?>,
        inverseKeyPath: ReferenceWritableKeyPath<U, T?>? = nil
    ) where U: Node {
        pendingRelationships.append(
            OneToOneRelationship(
                object: object,
                keyPath: keyPath,
                nodeID: nodeID,
                inverseKeyPath: inverseKeyPath
            )
        )
    }
    
    func registerOneToManyRelationship<T, U>(
        nodeIDs: [Node.ID],
        to object: T,
        keyPath: ReferenceWritableKeyPath<T, [U]>,
        inverseKeyPath: ReferenceWritableKeyPath<U, T?>? = nil
    ) where U: Node {
        pendingRelationships.append(
            OneToManyRelationship(
                object: object,
                keyPath: keyPath,
                nodeIDs: nodeIDs,
                inverseKeyPath: inverseKeyPath
            )
        )
    }
    
    func registerManyToOneRelationship<T, U>(
        nodeID: Node.ID,
        to object: T,
        keyPath: ReferenceWritableKeyPath<T, U?>,
        inverseKeyPath: ReferenceWritableKeyPath<U, [T]>? = nil
    ) where U: Node {
        pendingRelationships.append(
            ManyToOneRelationship(
                object: object,
                keyPath: keyPath,
                nodeID: nodeID,
                inverseKeyPath: inverseKeyPath
            )
        )
    }
    
    func resolveRelationships(nodes: [Node]) {
        let nodes: [Node.ID: Node] = nodes.reduce(into: [:]) {
            $0[$1.id] = $1
        }
        
        pendingRelationships.forEach { $0.resolve(nodes: nodes) }
        pendingRelationships = []
    }
}

@available(iOS 13.0, *)
fileprivate protocol PendingRelationship {
    func resolve(
        nodes: [Node.ID: Node]
    )
}

@available(iOS 13.0, *)
fileprivate struct OneToOneRelationship<T, U>: PendingRelationship where U: Node {
    var object: T
    var keyPath: ReferenceWritableKeyPath<T, U?>
    var nodeID: Node.ID
    var inverseKeyPath: ReferenceWritableKeyPath<U, T?>?
    
    func resolve(nodes: [Node.ID : Node]) {
        guard let node = nodes[nodeID] as? U else {
            assertionFailure("""
                Failed to resolve relationship. No node found with id \
                \(nodeID).
                """
            )
            judo_log(.error, "Failed to resolve one to one relationship. No node found with id %@", nodeID)
            return
        }
        
        object[keyPath: keyPath] = node
        
        if let inverseKeyPath = inverseKeyPath {
            node[keyPath: inverseKeyPath] = object
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct OneToManyRelationship<T, U>: PendingRelationship where U: Node {
    var object: T
    var keyPath: ReferenceWritableKeyPath<T, [U]>
    var nodeIDs: [Node.ID]
    var inverseKeyPath: ReferenceWritableKeyPath<U, T?>?
    
    func resolve(nodes: [Node.ID : Node]) {
        object[keyPath: keyPath] = nodeIDs.compactMap { nodeID in
            guard let node = nodes[nodeID] as? U else {
                assertionFailure("""
                    Failed to resolve relationship. No node found with id \
                    \(nodeID).
                    """
                )
                judo_log(.error, "Failed to resolve one to many relationship. No node found with id %@", nodeID)
                
                return nil
            }
            
            if let inverseKeyPath = inverseKeyPath {
                node[keyPath: inverseKeyPath] = object
            }
            
            return node
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct ManyToOneRelationship<T, U>: PendingRelationship where U: Node {
    var object: T
    var keyPath: ReferenceWritableKeyPath<T, U?>
    var nodeID: Node.ID
    var inverseKeyPath: ReferenceWritableKeyPath<U, [T]>?
    
    func resolve(nodes: [Node.ID : Node]) {
        guard let node = nodes[nodeID] as? U else {
            assertionFailure("""
                Failed to resolve relationship. No node found with id \
                \(nodeID).
                """
            )
            judo_log(.error, "Failed to resolve many to one relationship. No node found with id %@", nodeID)
            
            return
        }
        
        object[keyPath: keyPath] = node
        
        if let inverseKeyPath = inverseKeyPath {
            node[keyPath: inverseKeyPath].append(object)
        }
    }
}
