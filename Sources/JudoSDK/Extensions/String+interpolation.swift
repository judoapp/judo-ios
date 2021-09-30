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

// Reusable formatters since instantiating them is an expensive operation
private let dateFormatter = DateFormatter()

private let numberFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    return numberFormatter
}()

private let defaultDateCreator = ISO8601DateFormatter()

// Use the local variant when the date string omits time zone
private let localDateCreator: ISO8601DateFormatter = {
    let dateCreator = ISO8601DateFormatter()
    dateCreator.formatOptions.remove(.withTimeZone)
    dateCreator.timeZone = NSTimeZone.local
    return dateCreator
}()

private typealias Helper = ([String]) throws -> String?

extension String {
    func evaluatingExpressions(data: Any?, urlParameters: [String: String], userInfo: [String: Any]) -> String? {
        do {
            var result = self
            try result.evaluateExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo)
            return result
        } catch {
            judo_log(.error, "Invalid string interpolation expression, ignoring: '%@'. Reason: %@", self, error.debugDescription)
            return nil
        }
    }
    
    mutating func evaluateExpressions(data: Any?, urlParameters: [String: String], userInfo: [String: Any]) throws {
        func nextMatch() -> NSTextCheckingResult? {
            let range = NSRange(location: 0, length: self.utf16.count)
            let regex = try! NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}")
            return regex.firstMatch(in: self, options: [], range: range)
        }
        
        while let match = nextMatch() {
            let outerRange = Range(match.range(at: 0), in: self)!
            let innerRange = Range(match.range(at: 1), in: self)!
            let expression = String(self[innerRange])
            let replacement = try String.evaluate(expression: expression, data: data, urlParameters: urlParameters, userInfo: userInfo)
            replaceSubrange(outerRange, with: replacement)
        }
    }
    
    private static func evaluate(expression: String, data: Any?, urlParameters: [String: String], userInfo: [String: Any]) throws -> String {
        let regex = try! NSRegularExpression(pattern: "\"([^\"]*)\"|([^\\s]+)")
        let range = NSRange(location: 0, length: expression.utf16.count)
        let arguments = regex.matches(in: expression, range: range).map { match -> String in
            if let range = Range(match.range(at: 1), in: expression) {
                return String(expression[range])
            } else if let range = Range(match.range(at: 2), in: expression) {
                return String(expression[range])
            } else {
                fatalError()
            }
        }
        
        func stringValue(keyPath: String) throws -> String? {
            let value = JSONSerialization.value(
                forKeyPath: keyPath,
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
            
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
        
        let dateHelper: Helper = { arguments in
            guard arguments.first == "date" else {
                return nil
            }
            
            guard arguments.count == 3 else {
                throw StringExpressionError("Expected 3 arguments")
            }
            
            guard var dateString = try stringValue(keyPath: arguments[1]) else {
                throw StringExpressionError("Invalid argument")
            }
            
            // Remove milliseconds
            dateString = dateString.replacingOccurrences(
                of: "\\.\\d+",
                with: "",
                options: .regularExpression
            )
            
            // Some responses use a space as a separator between the date and
            // time instead of the letter T
            dateString = dateString.replacingOccurrences(of: " ", with: "T")
            
            let dateCreator = dateString.containsTimeZone
                ? defaultDateCreator
                : localDateCreator
            
            guard let date = dateCreator.date(from: dateString) else {
                throw StringExpressionError("Invalid date")
            }
            
            dateFormatter.dateFormat = arguments[2]
            return dateFormatter.string(from: date)
        }
        
        let lowercaseHelper: Helper = { arguments in
            guard arguments.first == "lowercase" else {
                return nil
            }
            
            guard arguments.count == 2 else {
                throw StringExpressionError("Expected 2 arguments")
            }
            
            guard let value = try stringValue(keyPath: arguments[1]) else {
                throw StringExpressionError("Invalid argument")
            }
            
            return value.lowercased()
        }
        
        let uppercaseHelper: Helper = { arguments in
            guard arguments.first == "uppercase" else {
                return nil
            }
            
            guard arguments.count == 2 else {
                throw StringExpressionError("Expected 2 arguments")
            }
            
            guard let value = try stringValue(keyPath: arguments[1]) else {
                throw StringExpressionError("Invalid argument")
            }
            
            return value.uppercased()
        }
        
        let replaceHelper: Helper = { arguments in
            guard arguments.first == "replace" else {
                return nil
            }
            
            guard arguments.count == 4 else {
                throw StringExpressionError("Expected 4 arguments")
            }
            
            guard let value = try stringValue(keyPath: arguments[1]) else {
                throw StringExpressionError("Invalid argument")
            }
            
            return value.replacingOccurrences(
                of: arguments[2],
                with: arguments[3]
            )
        }
        
        let echoHelper: Helper = { arguments in
            guard arguments.count == 1 else {
                return nil
            }
            
            return try stringValue(keyPath: arguments[0])
        }
        
        let helpers = [
            dateHelper,
            lowercaseHelper,
            uppercaseHelper,
            replaceHelper,
            echoHelper
        ]
        
        guard let result = try helpers.evaluate(arguments: arguments) else {
            throw StringExpressionError("Invalid expression \"\(expression)\"")
        }
        
        return result
    }
}

private extension String {
    var containsTimeZone: Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: "T.*[\\+\\-Z]")
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

private extension Array where Element == Helper {
    func evaluate(arguments: [String]) throws -> String? {
        for helper in self {
            if let result = try helper(arguments) {
                return result
            }
        }
        
        return nil
    }
}

private struct StringExpressionError: Error {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
}
