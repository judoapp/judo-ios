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

import JudoModel
import SwiftUI

@available(iOS 13.0, *)
struct CollectionView: View {
    @Environment(\.data) private var data
    var collection: Collection

    var body: some View {
        if let items = items, !items.isEmpty {
            ForEach(Array(zip(items.indices, items)), id: \.0) { index, item in
                ForEach(collection.children.compactMap { $0 as? Layer }) {
                    LayerView(layer: $0)
                }
                .environment(\.data, item)
                .contentShape(SwiftUI.Rectangle())
            }
        } else {
            // Work around a bug in LazyVStack where initially empty contents cause it to never render anything that appears later (such as asynchronously loaded data from a Collection).
            SwiftUI.Rectangle().fill(Color.clear).frame(width: 1, height: 1)
        }
    }
    
    private var items: [JSONObject]? {
        let tokens = collection.dataKey.split(separator: ".").map { String($0) }
        let value = tokens.reduce(data as Any?) { result, token in
            if let result = result as? JSONObject {
                return result[token]
            } else {
                return nil
            }
        }
        
        guard var result = value as? [JSONObject] else {
            return nil
        }
        
        collection.filters.forEach { filter in
            result = result.filter { data in
                switch (filter.predicate, data[filter.dataKey], filter.value) {
                case (.equals, let a as String, let b as String):
                    return a == b
                case (.equals, let a as Double, let b as Double):
                    return a == b
                case (.doesNotEqual, let a as String, let b as String):
                    return a != b
                case (.doesNotEqual, let a as Double, let b as Double):
                    return a != b
                case (.isGreaterThan, let a as Double, let b as Double):
                    return a > b
                case (.isLessThan, let a as Double, let b as Double):
                    return a < b
                case (.isSet, .some, _):
                    return true
                case (.isSet, .none, _):
                    return false
                case (.isNotSet, .some, _):
                    return false
                case (.isNotSet, .none, _):
                    return true
                case (.isTrue, let value as Bool, _):
                    return value == true
                case (.isFalse, let value as Bool, _):
                    return value == false
                default:
                    return true
                }
            }
        }
        
        if !collection.sortDescriptors.isEmpty {
            result.sort { a, b in
                for descriptor in collection.sortDescriptors {
                    switch (a[descriptor.dataKey], b[descriptor.dataKey]) {
                    case (let a as String, let b as String) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    case (let a as Double, let b as Double) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    case (let a as Bool, let b as Bool) where a != b:
                        return descriptor.ascending ? a == false : a == true
                    case (let a as Date, let b as Date) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    default:
                        break
                    }
                }
                
                return false
            }
        }
        
        if let index = collection.limit.map({ $0.startAt - 1 }) {
            if result.indices.contains(index) {
                result = Array(result.suffix(from: index))
            } else {
                result = []
            }
        }
        
        result = Array(result.prefix(collection.limit?.show ?? 100))
        
        return result
    }
}
