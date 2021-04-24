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

// Reusable formatters since instantiating them is an expensive operation
private let dateFormatter = DateFormatter()
private let numberFormatter = NumberFormatter()

private typealias Helper = ([String]) throws -> String?

extension String {
    func evaluatingExpressions(data: JSONObject?, userInfo: UserInfo) -> String? {
        do {
            var result = self
            try result.evaluateExpressions(data: data, userInfo: userInfo)
            return result
        } catch {
            judo_log(.error, "Invalid string interpolation expression, ignoring: '%@'. Reason: %@", self, error.debugDescription)
            return nil
        }
    }
    
    mutating func evaluateExpressions(data: JSONObject?, userInfo: UserInfo) throws {
        func nextMatch() -> NSTextCheckingResult? {
            let range = NSRange(location: 0, length: self.utf16.count)
            let regex = try! NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}")
            return regex.firstMatch(in: self, options: [], range: range)
        }
        
        while let match = nextMatch() {
            let outerRange = Range(match.range(at: 0), in: self)!
            let innerRange = Range(match.range(at: 1), in: self)!
            let expression = String(self[innerRange])
            let replacement = try String.evaluate(expression: expression, data: data, userInfo: userInfo)
            replaceSubrange(outerRange, with: replacement)
        }
    }
    
    static func evaluate(expression: String, data: JSONObject?, userInfo: UserInfo) throws -> String {
        let regex = try! NSRegularExpression(pattern: "\"(.*)\"|([\\w\\.]+)")
        let wholeString = NSRange(location: 0, length: expression.utf16.count)
        let arguments = regex.matches(in: expression, range: wholeString).map { match -> String in
            if let range = Range(match.range(at: 1), in: expression) {
                return String(expression[range])
            } else if let range = Range(match.range(at: 2), in: expression) {
                return String(expression[range])
            } else {
                fatalError()
            }
        }
        
        let dataHelper: Helper = { arguments in
            guard arguments.count == 1, arguments.first!.hasPrefix("data.") else {
                return nil
            }
            
            let key = String(arguments[0].dropFirst("data.".count))
            let tokens = key.split(separator: ".").map { String($0) }
            let value = tokens.reduce(data as Any?) { result, token in
                if let result = result as? JSONObject {
                    return result[token]
                } else {
                    return nil
                }
            }
            
            switch value {
            case let string as String:
                return string
            case let double as Double:
                return numberFormatter.string(from: double as NSNumber)
            case let bool as Bool:
                return bool ? "true" : "false"
            default:
                throw StringExpressionError("Unexpected value")
            }
        }
        
        let userInfoHelper: Helper = { arguments in
            guard arguments.count == 1, arguments.first!.hasPrefix("user.") else {
                return nil
            }
            
            let key = String(arguments[0].dropFirst("user.".count))
            guard let value = userInfo[key] else {
                throw StringExpressionError("UserInfo key \"\(key)\"  not found")
            }
            
            return value
        }
        
        let dateHelper: Helper = { arguments in
            guard arguments.first == "date" else {
                return nil
            }
            
            guard arguments.count == 3 else {
                throw StringExpressionError("Expected 3 arguments")
            }
            
            let helpers = [dataHelper, userInfoHelper]
            guard let value = try helpers.evaluate(arguments: [arguments[1]]) else {
                throw StringExpressionError("Invalid argument")
            }
            
            // Remove milliseconds
            let dateString = value.replacingOccurrences(
                of: "\\.\\d+",
                with: "",
                options: .regularExpression
            )
            
            guard let date = ISO8601DateFormatter().date(from: dateString) else {
                throw StringExpressionError("Invalid date")
            }
            
            dateFormatter.dateFormat = arguments[2]
            return dateFormatter.string(from: date)
        }
        
        let helpers = [
            dateHelper,
            dataHelper,
            userInfoHelper
        ]
        
        guard let result = try helpers.evaluate(arguments: arguments) else {
            throw StringExpressionError("Invalid expression \"\(expression)\"")
        }
        
        return result
    }
}

extension Array where Element == Helper {
    func evaluate(arguments: [String]) throws -> String? {
        for helper in self {
            if let result = try helper(arguments) {
                return result
            }
        }
        
        return nil
    }
}

struct StringExpressionError: Error {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
}
