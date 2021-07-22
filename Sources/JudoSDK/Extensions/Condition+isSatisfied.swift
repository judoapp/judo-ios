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

extension Condition {
    func isSatisfied(data: Any?, urlParameters: [String: String], userInfo: [String: String]) -> Bool {
        let lhs = JSONSerialization.value(
            forKeyPath: keyPath,
            data: data,
            urlParameters: urlParameters,
            userInfo: userInfo
        )
        
        switch (predicate, self.value) {
        case (.equals, let value as String):
            let maybeValue = value.evaluatingExpressions(
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
            
            guard let rhs = maybeValue else {
                return false
            }
            
            return evaluate(lhs, equals: rhs)
        case (.equals, let rhs as Double):
            return evaluate(lhs, equals: rhs)
        case (.doesNotEqual, let value as String):
            let maybeValue = value.evaluatingExpressions(
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
            
            guard let rhs = maybeValue else {
                return true
            }
            
            return evaluate(lhs, doesNotEqual: rhs)
        case (.doesNotEqual, let rhs as Double):
            return evaluate(lhs, doesNotEqual: rhs)
        case (.isGreaterThan, let rhs as Double):
            return evaluate(lhs, isGreaterThan: rhs)
        case (.isLessThan, let rhs as Double):
            return evaluate(lhs, isLessThan: rhs)
        case (.isSet, _):
            return evaluate(isSet: lhs)
        case (.isNotSet, _):
            return evaluate(isNotSet: lhs)
        case (.isTrue, _):
            return evaluate(isTrue: lhs)
        case (.isFalse, _):
            return evaluate(isFalse: lhs)
        default:
            return false
        }
    }
    
    private func evaluate(_ lhs: Any?, equals rhs: String) -> Bool {
        guard let lhs = lhs as? String else {
            return false
        }
        
        return lhs == rhs
    }
    
    private func evaluate(_ lhs: Any?, equals rhs: Double) -> Bool {
        switch lhs {
        case let lhs as Double:
            return lhs == rhs
        case let lhs as String:
            return Double(lhs) == rhs
        default:
            return false
        }
    }
    
    private func evaluate(_ lhs: Any?, doesNotEqual rhs: String) -> Bool {
        guard let lhs = lhs as? String else {
            return true
        }
        
        return lhs != rhs
    }
    
    private func evaluate(_ lhs: Any?, doesNotEqual rhs: Double) -> Bool {
        switch lhs {
        case let lhs as Double:
            return lhs != rhs
        case let lhs as String:
            return Double(lhs) != rhs
        default:
            return true
        }
    }
    
    private func evaluate(_ lhs: Any?, isGreaterThan rhs: Double) -> Bool {
        switch lhs {
        case let lhs as Double:
            return lhs > rhs
        case let lhs as String:
            guard let lhs = Double(lhs) else {
                return false
            }
            
            return lhs > rhs
        default:
            return false
        }
    }
    
    private func evaluate(_ lhs: Any?, isLessThan rhs: Double) -> Bool {
        switch lhs {
        case let lhs as Double:
            return lhs < rhs
        case let lhs as String:
            guard let lhs = Double(lhs) else {
                return false
            }
            
            return lhs < rhs
        default:
            return false
        }
    }
    
    private func evaluate(isSet value: Any?) -> Bool {
        switch value {
        case let value?:
            return !(value is NSNull)
        case .none:
            return false
        }
    }
    
    private func evaluate(isNotSet value: Any?) -> Bool {
        switch value {
        case let value?:
            return value is NSNull
        case .none:
            return true
        }
    }
    
    private func evaluate(isTrue value: Any?) -> Bool {
        switch value {
        case let value as Bool:
            return value == true
        case let value as String:
            return value == "true"
        default:
            return false
        }
    }

    private func evaluate(isFalse value: Any?) -> Bool {
        switch value {
        case let value as Bool:
            return value == false
        case let value as String:
            return value == "false"
        default:
            return false
        }
    }
}
