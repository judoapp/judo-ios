import Foundation

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, range: range) != nil
    }

    func matches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        let range = NSRange(location: 0, length: string.utf16.count)
        return matches(in: string, options: options, range: range)
    }

    func matches(in string: String, groupIndex: Int) -> String? {
        guard let result = matches(in: string).first else {
            return nil
        }

        guard let range = Range(result.range(at: groupIndex), in: string) else {
            return nil
        }
        return String(string[range])
    }
}
