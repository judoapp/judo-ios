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
extension Collection {
    func items(data: Any?, urlParameters: [String: String], userInfo: [String: String]) -> [Any] {
        guard var result = JSONSerialization.value(forKeyPath: keyPath, data: data, urlParameters: urlParameters, userInfo: userInfo) as? [Any] else {
            return []
        }
        
        filters.forEach { condition in
            result = result.filter { data in
                condition.isSatisfied(
                    data: data,
                    urlParameters: urlParameters,
                    userInfo: userInfo
                )
            }
        }
        
        if !sortDescriptors.isEmpty {
            result.sort { a, b in
                for descriptor in sortDescriptors {
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
        
        if let limit = limit {
            let limitedRange = result.indices.clamped(to: (limit.startAt - 1)..<result.endIndex)
            result = Array(result[limitedRange])
        }
        
        result = Array(result.prefix(limit?.show ?? 100))
        return result
    }
}
