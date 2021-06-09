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
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    var collection: Collection

    var body: some View {
        if let items = items {
            ForEach(Array(zip(items.indices, items)), id: \.0) { index, item in
                ForEach(collection.children.compactMap { $0 as? Layer }) {
                    LayerView(layer: $0)
                }
                .environment(\.data, item)
                .contentShape(SwiftUI.Rectangle())
            }
        }
    }
    
    private var items: [Any]? {
        guard var result = JSONSerialization.value(forKeyPath: collection.keyPath, data: data, urlParameters: urlParameters, userInfo: userInfo) as? [Any] else {
            return nil
        }
        
        collection.filters.forEach { condition in
            result = result.filter { data in
                condition.isSatisfied(
                    data: data,
                    urlParameters: urlParameters,
                    userInfo: userInfo
                )
            }
        }
        
        if !collection.sortDescriptors.isEmpty {
            result.sort { a, b in
                for descriptor in collection.sortDescriptors {
                    let a = JSONSerialization.value(
                        forKeyPath: descriptor.keyPath,
                        data: a,
                        urlParameters: urlParameters,
                        userInfo: userInfo
                    )
                    
                    let b = JSONSerialization.value(
                        forKeyPath: descriptor.keyPath,
                        data: b,
                        urlParameters: urlParameters,
                        userInfo: userInfo
                    )
                    
                    switch (a, b) {
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
