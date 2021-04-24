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
import JudoModel

@available(iOS 13.0, *)
extension Sequence where Element: Node {
    
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
