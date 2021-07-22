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

public struct Condition: Decodable {
    public enum Predicate: String, Decodable {
        case equals
        case doesNotEqual
        case isGreaterThan
        case isLessThan
        case isSet
        case isNotSet
        case isTrue
        case isFalse
    }
    
    public var keyPath: String
    public var predicate: Predicate
    public var value: Any?
    
    public init(keyPath: String, predicate: Predicate, value: Any? = nil) {
        self.keyPath = keyPath
        self.predicate = predicate
        self.value = value
    }

    private enum CodingKeys: String, CodingKey {
        case keyPath
        case predicate
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyPath = try container.decode(String.self, forKey: .keyPath)
        predicate = try container.decode(Predicate.self, forKey: .predicate)
        
        if let value = try? container.decode(String.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Double.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Bool.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Date.self, forKey: .value) {
            self.value = value
        }
    }
}
