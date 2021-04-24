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

import SwiftUI

@available(iOS 13.0, *)
public struct Frame: Decodable, Equatable {
    /// A fixed width for the frame.
    public let width: CGFloat?
    /// A fixed height for the frame.
    public let height: CGFloat?
    /// The minimum width of the resulting frame.
    public let minWidth: CGFloat?
    /// The maximum width of the resulting frame.
    public let maxWidth: CGFloat?
    /// The minimum height of the resulting frame.
    public let minHeight: CGFloat?
    /// The maximum height of the resulting frame.
    public let maxHeight: CGFloat?
    /// The alignment of the node inside the resulting frame.
    /// The alignment only applies if the node is smaller than the size of the resulting frame.
    public let alignment: Alignment

    public var isFixed: Bool {
        minWidth == nil && maxWidth == nil && minHeight == nil && maxHeight == nil
    }
    
    public init(width: CGFloat?, height: CGFloat?, minWidth: CGFloat?, maxWidth: CGFloat?, minHeight: CGFloat?, maxHeight: CGFloat?, alignment: Alignment) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
    }

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case minWidth
        case maxWidth
        case minHeight
        case maxHeight
        case alignment
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        width = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        height = try container.decodeIfPresent(CGFloat.self, forKey: .height)
        minWidth = try container.decodeIfPresent(CGFloat.self, forKey: .minWidth)
        minHeight = try container.decodeIfPresent(CGFloat.self, forKey: .minHeight)

        if let maxWidthStringValue = try? container.decodeIfPresent(String.self, forKey: .maxWidth), maxWidthStringValue == "inf" {
            maxWidth = CGFloat.greatestFiniteMagnitude
        } else {
            maxWidth = try container.decodeIfPresent(CGFloat.self, forKey: .maxWidth)
        }

        if let maxHeightStringValue = try? container.decodeIfPresent(String.self, forKey: .maxHeight), maxHeightStringValue == "inf" {
            maxHeight = CGFloat.greatestFiniteMagnitude
        } else {
            maxHeight = try container.decodeIfPresent(CGFloat.self, forKey: .maxHeight)
        }

        alignment = try container.decode(Alignment.self, forKey: .alignment)
    }
}
