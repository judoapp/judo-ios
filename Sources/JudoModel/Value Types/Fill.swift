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

public enum Fill: Decodable, Hashable {    
    case flat(_ color: ColorVariants)
    case gradient(_ gradient: GradientVariants)

    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case color
        case gradient
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .typeName)
        switch typeName {
        case "FlatFill":
            let color = try container.decode(ColorVariants.self, forKey: .color)
            self = .flat(color)
        case "GradientFill":
            let gradient = try container.decode(GradientVariants.self, forKey: .gradient)
            self = .gradient(gradient)
        default:
            judo_log(.error, "Unsupported fill case name: %@", typeName)
            assertionFailure("Unsupported value \(typeName)")
            self = .flat(.clear)
        }
    }
}
