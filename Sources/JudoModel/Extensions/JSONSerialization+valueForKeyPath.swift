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
        
        var result: Any? = object
        
        // The following code traverses through the `result` object by applying
        // the `keyPath` which is a string comprised of object keys separated by
        // the dot character. The `keyPath` is first split into tokens, however
        // a token is not necessarily equal to a key because we can not
        // guarantee that a key does not contain the dot character itself.
        //
        // E.g. consider the following JSON object:
        //
        // ```
        // {
        //   "foo": {
        //     "bar.baz": true
        //   }
        // }
        // ```
        //
        // To access the boolean value, this method would be called with the
        // `keyPath` value of "foo.bar.baz" which results in three tokens but
        // must be processed as two keys: "foo" and "bar.baz".
        //
        // To achieve this we attempt to construct a key by popping values from
        // the list of tokens until we find a valid key. If no valid key can be
        // constructed before we run out of tokens, nil is returned.
        
        var tokens = keyPath.split(separator: ".").map { String($0) }
        
        if tokens.isEmpty {
            return nil
        }
        
        outer: while !tokens.isEmpty, let object = result as? [String: Any] {
            var paths = [String]()
            while !tokens.isEmpty {
                paths.append(tokens.removeFirst())
                let key = paths.joined(separator: ".")
                if let nextResult = object[key] {
                    result = nextResult
                    continue outer
                }
            }
        }
        
        return result
    }
}
