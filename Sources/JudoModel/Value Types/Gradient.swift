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

import CoreGraphics

public struct GradientStop: Hashable, Codable {
    /// A decimal between 0-1 indicating where along the gradient the color is reached.
    public var position: CGFloat
    /// The color that the gradient should pass through at this position.
    public var color: JudoModel.Color
    
    public init(position: CGFloat, color: Color) {
        self.position = position
        self.color = color
    }
}

public struct Gradient: Hashable, Decodable {
    /// In a parametric coordinate space, between 0 and 1.
    public let from: CGPoint
    /// In a parametric coordinate space, between 0 and 1.
    public let to: CGPoint
    /// Color and stop point data.
    public let stops: [GradientStop]
    
    public init(from: CGPoint, to: CGPoint, stops: [GradientStop]) {
        self.from = from
        self.to = to
        self.stops = stops
    }
    
    public static var `clear`: Gradient {
        return Gradient(
            from: CGPoint(x: 0.0, y: 0.5),
            to: CGPoint(x: 1.0, y: 0.5),
            stops: [
                GradientStop(position: 0, color: Color(red: 0, green: 0, blue: 0, alpha: 0)),
                GradientStop(position: 1, color: Color(red: 0, green: 0, blue: 0, alpha: 0))
            ]
        )
    }
    
    // MARK: Decodable

    private enum CodingKeys: String, CodingKey {
        case from
        case to
        case stops
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let fromArray = try container.decode([CGFloat].self, forKey: .from)
        from = CGPoint(x: CGFloat(fromArray[0]), y: CGFloat(fromArray[1]))

        let toArray = try container.decode([CGFloat].self, forKey: .to)
        to = CGPoint(x: CGFloat(toArray[0]), y: CGFloat(toArray[1]))

        stops = try container.decode([GradientStop].self, forKey: .stops)
    }
}
