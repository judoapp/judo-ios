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

extension JSONSerialization {
    /// A utility function for accessing a value in a given data context by a stringly-typed key path. The data
    /// context encompasses JSON data made available from a `DataSource` as well as the
    /// document's `urlParameters` and `userInfo`. The `data` parameter is expected to be a
    /// valid JSON value as defined by the `JSONSerialization` class.
    ///
    /// - Returns: The value defined at the supplied key path where `data` refers to the JSON
    /// data, `url` refers to the document's `urlParameters` and `user` refers to the document's
    /// `userInfo`. If there is no value at the specified `keyPath`, nil is returned.
    public static func value(forKeyPath keyPath: String, data: Any?, urlParameters: [String: String], userInfo: [String: Any]) -> Any? {
        var object: [String: Any] = [
            "url": urlParameters.reduce(into: [:]) {
                $0[$1.0] = $1.1
            },
            "user": userInfo.reduce(into: [:]) {
                $0[$1.0] = $1.1
            }
        ]
        
        if let data = data {
            object["data"] = data
        }
       
        return fetchValueByKeyPath(dict: object, keyPath: keyPath)
    }
}

/// Implements support for object/dictionary traversal using traversal operators in the form of `.` (periods).
///
/// Also handles keys that have periods in them by greedily matching without traversal beforehand.
///
/// E.g. consider the following JSON object:
///
/// ```
/// {
///   "foo": {
///     "bar.baz": true
///   }
/// }
/// ```
///
/// To access the boolean value, this method would be called with the
/// `keyPath` value of "foo.bar.baz" which results in three tokens but
/// must be processed as two keys: "foo" and "bar.baz".
private func fetchValueByKeyPath(dict: [String: Any], keyPath: String) -> Any? {
    // build out a list of all the possible splits: ie each possible split if the keypath, done at a single possible period separator.  However start the range at one, since one key at least must always be present.
    guard let firstIndex = keyPath.indices.first, let lastIndex = keyPath.indices.last else {
        // if keyPath empty string, try that directly on the dict.
        return dict[keyPath]
    }
    
    let periodIndices = keyPath.indices.filter { index in
        keyPath[index] == "."
    }
    
    struct Match {
        var key: String
        var remainder: String
    }
    
    let periodPossibilities: [Match] = periodIndices.flatMap { periodIndex -> [Match] in
        // there are three cases. either the key greedily takes the period, the remainder does, or neither do.
        
        // greedy key:
        let greedyKey = Match(
            key: String(keyPath[firstIndex...periodIndex]),
            remainder: String(keyPath[periodIndex...lastIndex].dropFirst())
        )

        // greedy remainder:
        let greedyRemainder = Match(
            key: String(keyPath[firstIndex..<periodIndex]),
            remainder: String(keyPath[periodIndex...lastIndex])
        )

        // greedy neither:
        let neitherGreedy = Match(
            key: String(keyPath[firstIndex..<periodIndex]),
            remainder: String(keyPath[periodIndex...lastIndex].dropFirst())
        )
        
        return [greedyKey, greedyRemainder, neitherGreedy]
    }
    
    let possibilities = periodPossibilities + [Match(key: keyPath, remainder: "")]
    
    // start from the longest possible key, to ensure greedy matching of a key containing multiple periods.
    let possibleMatch = possibilities.last { entry in
        dict.keys.contains(entry.key)
    }
    
    guard let match = possibleMatch else {
        // key, in any of the possible permutations, not present at all.
        return nil
    }
    
    if match.remainder.isEmpty {
        return dict[match.key]
    }
    
    // there is a remaining path. This means the nested value must be a dictionary.
    guard let nestedDictionary = dict[match.key] as? [String: Any] else {
        judo_log(.error, "Invalid nested keypath into a non-dictionary value: %s", match.remainder)
        return nil
    }
    return fetchValueByKeyPath(dict: nestedDictionary, keyPath: match.remainder)
}
