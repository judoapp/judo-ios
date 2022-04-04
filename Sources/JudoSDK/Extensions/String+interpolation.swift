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

private let customizableNumberFormatter = CustomizableNumberFormatter()

private let defaultDateCreator = ISO8601DateFormatter()

// Use the local variant when the date string omits time zone
private let localDateCreator: ISO8601DateFormatter = {
    let dateCreator = ISO8601DateFormatter()
    dateCreator.formatOptions.remove(.withTimeZone)
    dateCreator.timeZone = NSTimeZone.local
    return dateCreator
}()

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

        let expressionHelper = ExpressionHelper(data: data, urlParameters: urlParameters, userInfo: userInfo)

        func nextMatch(for pattern: String = "\\{\\{(.*?)\\}\\}", in string: String) -> NSTextCheckingResult? {
            let range = NSRange(location: 0, length: string.utf16.count)
            let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            return regex.firstMatch(in: string, options: [], range: range)
        }

        func getParenthesisMatch(for expression: String) throws -> String {
            var expression = expression
            if let match = nextMatch(for: "\\((.*)\\)", in: expression) {
                let outerRange = Range(match.range(at: 0), in: expression)!
                let innerRange = Range(match.range(at: 1), in: expression)!
                let newExp = String(expression[innerRange])

                let result = try getParenthesisMatch(for: newExp)
                expression.replaceSubrange(outerRange, with: result)
            }

            // Wrap the evaluated result in quotation marks, to keep it as one argument.
            let evaluatedResult = try expressionHelper.evaluate(expression: expression)
            return "\"\(evaluatedResult)\""
        }

        while let match = nextMatch(in: self) {
            let outerRange = Range(match.range(at: 0), in: self)!
            let innerRange = Range(match.range(at: 1), in: self)!
            let expression = String(self[innerRange])

            let result = try getParenthesisMatch(for: expression)

            // Perform one last evaluation on the result.
            let newResult = try expressionHelper.evaluate(expression: result)

            replaceSubrange(outerRange, with: newResult)
        }
    }
    
    /// Checks to make sure that the string is enclosed in quotation marks
     fileprivate var isEnclosedInQuotes: Bool {
         self.starts(with: "\"") && self.hasSuffix("\"")
     }

     /// Removes enclosing quotation marks from a string
     fileprivate func removeQuotationMarks() -> String {
         guard self.isEnclosedInQuotes else {
             return self
         }
         return String(self.dropFirst(1).dropLast(1))
     }
}

private struct ExpressionHelper {

    typealias Helper = ([String]) throws -> String?

    private let data: Any?
    private let urlParameters: [String: String]
    private let userInfo: [String: Any]

    init(data: Any?, urlParameters: [String: String], userInfo: [String: Any]) {
        self.data = data
        self.urlParameters = urlParameters
        self.userInfo = userInfo
    }

    /// Evaluates the passed expression
    func evaluate(expression: String) throws -> String {
        // Use RawStrings to make the Regex patterns easier to read.
        let pattern = #"(^".*?"$)|(".*?")|([^\s]+)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: expression.utf16.count)
        let arguments = regex.matches(in: expression, range: range).map { match -> String in
            if let range = Range(match.range(at: 1), in: expression) {
                return String(expression[range])
            } else if let range = Range(match.range(at: 2), in: expression) {
                return String(expression[range])
            } else if let range = Range(match.range(at: 3), in: expression) {
                return String(expression[range])
            } else {
                fatalError()
            }
        }

        guard let result = try getHelpers().evaluate(arguments: arguments) else {
            throw StringExpressionError("Invalid expression \"\(expression)\"")
        }

        return result
    }

    /// Checks the data, urlParameters, userInfo, and helpers for the passed keyPath.
    /// If a string literal is passed, it removes the surrounding quotation marks
    /// and returns its value.
    private func stringValue(keyPathOrStringLiteral: String) throws -> String? {
        // Check if keyPathOrStringLiteral starts and ends with "", if so remove them and return it,
        // this allows for string literals to be parsed.
        if keyPathOrStringLiteral.isEnclosedInQuotes {
            return keyPathOrStringLiteral.removeQuotationMarks()
        }

        let value = JSONSerialization.value(
            forKeyPath: keyPathOrStringLiteral,
            data: data,
            urlParameters: urlParameters,
            userInfo: userInfo
        )

        switch value {
        case let string as String:
            return string
        case let int as Int:
            return customizableNumberFormatter.formatString(int as NSNumber, using: .none)
        case let double as Double:
            return customizableNumberFormatter.formatString(double as NSNumber, using: .none)
        case let bool as Bool:
            return bool ? "true" : "false"
        default:
            throw StringExpressionError.unexpectedValue
        }
    }

    /// Collects all the `Helper`s together so that they can be used in one pipeline
    private func getHelpers() -> [Helper] {

        let dateFormatHelper = createDateFormatHelper()

        let numberFormatHelper = createNumberFormatHelper()

        let lowercaseHelper = createTwoArgumentHelper(keyWord: "lowercase") { $0.lowercased() }

        let uppercaseHelper = createTwoArgumentHelper(keyWord: "uppercase") { $0.uppercased() }

        let replaceHelper = createReplaceHelper()

        let dropFirstHelper = createThreeArgumentHelper(keyWord: "dropFirst") { String($0.dropFirst($1)) }

        let dropLastHelper = createThreeArgumentHelper(keyWord: "dropLast") { String($0.dropLast($1)) }

        let prefixHelper = createThreeArgumentHelper(keyWord: "prefix") { String($0.prefix($1)) }

        let suffixHelper = createThreeArgumentHelper(keyWord: "suffix") { String($0.suffix($1)) }

        let echoHelper: Helper = { arguments in
            guard arguments.count == 1 else {
                return nil
            }

            return try stringValue(keyPathOrStringLiteral: arguments[0])
        }

        // The helpers will check each one until it finds one that it can use.
        // If a `keyWord` is passed but it does not match the requirements of the
        // helper then the helper will throw an error and the parsing will stop.
        // The echoHelper must be last as it is only looking for a single argument.
        return [
            dateFormatHelper,
            numberFormatHelper,
            lowercaseHelper,
            uppercaseHelper,
            replaceHelper,
            dropFirstHelper,
            dropLastHelper,
            prefixHelper,
            suffixHelper,
            echoHelper
        ]
    }

    /// Creates a two argument `Helper` where the second argument is a `String`.
    private func createTwoArgumentHelper(keyWord: String, computeValue: @escaping (String) -> String) -> Helper {
        { arguments in
            guard arguments.first == keyWord else {
                return nil
            }

            guard arguments.count == 2 else {
                throw StringExpressionError.argumentCount(2)
            }

            guard let value = try stringValue(keyPathOrStringLiteral: arguments[1]) else {
                throw StringExpressionError.invalidArgument
            }

            return computeValue(value)
        }
    }

    /// Creates a three argument `Helper` were the second argument is a `String` and the third argument is an `Int`.
    private func createThreeArgumentHelper(keyWord: String, computeValue: @escaping (String, Int) -> String) -> Helper {
        { arguments in
            guard arguments.first == keyWord else {
                return nil
            }

            guard arguments.count == 3 else {
                throw StringExpressionError.argumentCount(3)
            }

            guard let value = try stringValue(keyPathOrStringLiteral: arguments[1]) else {
                throw StringExpressionError.invalidArgument
            }

            guard let places = Int(arguments[2]) else {
                throw StringExpressionError.expectedInteger
            }

            return computeValue(value, places)
        }
    }

    private func createDateFormatHelper() -> Helper {
        { arguments in
            // For legacy customers who are using date as the first argument
            guard arguments.first == "dateFormat" || arguments.first == "date" else {
                return nil
            }

            guard arguments.count == 3 else {
                throw StringExpressionError.argumentCount(3)
            }

            guard var dateString = try stringValue(keyPathOrStringLiteral: arguments[1]) else {
                throw StringExpressionError.invalidArgument
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
                throw StringExpressionError.invalidDate
            }

            // The formatting must be contained within quotation marks.
            // However these additional quotation marks must be removed before we can set
            // the dateFormat on the dateFormatter. If the format is not contained within
            // quotation marks then it is considered to be invalid.
            if arguments[2].isEnclosedInQuotes {
                dateFormatter.dateFormat = arguments[2].removeQuotationMarks()
            } else {
                throw StringExpressionError.invalidDateFormatPassed
            }

            return dateFormatter.string(from: date)
        }
    }

    private func createReplaceHelper() -> Helper {
        { arguments in
            guard arguments.first == "replace" else {
                return nil
            }

            guard arguments.count == 4 else {
                throw StringExpressionError.argumentCount(4)
            }

            guard let value = try stringValue(keyPathOrStringLiteral: arguments[1]) else {
                throw StringExpressionError.invalidArgument
            }
            
            // The additional arguments must be contained within quotation marks.
            // However these additional quotation marks must be removed before we can
            // perform the replace. If it is missing the quotation marks then it is considered to be invalid.
            guard arguments[2].isEnclosedInQuotes && arguments[3].isEnclosedInQuotes else {
                throw StringExpressionError.invalidReplaceArguments
            }

            return value.replacingOccurrences(
                of: arguments[2].removeQuotationMarks(),
                with: arguments[3].removeQuotationMarks()
            )
        }
    }

    private func createNumberFormatHelper() -> Helper {
        { arguments in
            guard arguments.first == "numberFormat" else {
                return nil
            }

            // We can have two or three arguments
            guard arguments.count >= 2 && arguments.count <= 3 else {
                throw StringExpressionError("Expected at least 2 arguments")
            }

            // If we have only two arguments we want the default value to be decimal
            var numberStyle: NumberFormatter.Style = .decimal

            // If we have a third argument then it should be the numberStyle
            if arguments.count == 3, let passedNumberStyle = NumberStyle.getStyle(from: arguments[2]) {
                numberStyle = passedNumberStyle
            }

            guard let value = try numberValue(keyPathOrStringLiteral: arguments[1]) else {
                throw StringExpressionError.invalidArgument
            }

            return customizableNumberFormatter.formatString(value, using: numberStyle)
        }
    }

    /// Similar to `stringValue` this checks the data, urlParameters, userInfo or the passed StringLiteral
    /// to see if it can be converted into a NSNumber.
    private func numberValue(keyPathOrStringLiteral: String) throws -> NSNumber? {
        // Check if keyPathOrStringLiteral starts and ends with "", if so remove them and return it,
        // this allows for string literals to be parsed.
        if keyPathOrStringLiteral.starts(with: "\"") && keyPathOrStringLiteral.hasSuffix("\"") {
            let updatedString = String(keyPathOrStringLiteral.dropFirst(1).dropLast(1))
            return Double(updatedString) as NSNumber?
        }

        let value = JSONSerialization.value(
            forKeyPath: keyPathOrStringLiteral,
            data: data,
            urlParameters: urlParameters,
            userInfo: userInfo
        )

        switch value {
        case let string as String:
            return Double(string) as NSNumber?
        case let int as Int:
            return int as NSNumber
        case let double as Double:
            return double as NSNumber
        default:
            throw StringExpressionError.unexpectedValue
        }
    }
}

private enum NumberStyle: String {
    case none
    case decimal
    case currency
    case percent

    var style: NumberFormatter.Style {
        switch self {
            case .none: return .none
            case .decimal: return .decimal
            case .currency: return .currency
            case .percent: return .percent
        }
    }

    static func getStyle(from style: String) -> NumberFormatter.Style? {
        guard style.isEnclosedInQuotes else {
            return nil
        }
        let stringStyle = style.removeQuotationMarks()
        return NumberStyle(rawValue: stringStyle)?.style
    }
}

private class CustomizableNumberFormatter: NumberFormatter {

    override init() {
        super.init()
        resetToDefault()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func formatString(_ number: NSNumber, using numberStyle: NumberFormatter.Style) -> String? {
        defer { resetToDefault() }
        self.numberStyle = numberStyle
        let formattedString = self.string(from: number)
        return formattedString
    }

    private func resetToDefault() {
        numberStyle = .none
    }
}

private extension String {
    var containsTimeZone: Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: "T.*[\\+\\-Z]")
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

private extension Array where Element == ExpressionHelper.Helper {
    func evaluate(arguments: [String]) throws -> String? {
        for helper in self {
            if let result = try helper(arguments) {
                return result
            }
        }

        return nil
    }
}

public struct StringExpressionError: Error, Equatable {
    public var message: String

    public init(_ message: String) {
        self.message = message
    }
}

extension StringExpressionError {
    public static let invalidArgument = StringExpressionError("Invalid argument")

    public static let unexpectedValue = StringExpressionError("Unexpected value")

    public static let expectedInteger = StringExpressionError("Expected an integer")
    
    public static let invalidReplaceArguments = StringExpressionError("Invalid replace arguments")

    public static let invalidDate = StringExpressionError("Invalid date")

    public static let invalidDateFormatPassed = StringExpressionError("Invalid date format passed")

    public static func argumentCount(_ count: Int) -> StringExpressionError {
        StringExpressionError("Expected \(count) arguments")
    }
}
