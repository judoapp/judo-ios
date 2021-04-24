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

public struct Accessibility: Decodable, Hashable {
    /// Hides the node from system accessibility features.
    /// When used on an Image this indicates to features
    /// such as VoiceOver that the image is decorative and
    /// can be safely ignored. When this property is true,
    /// accessibility is essentially disabled and all the other
    /// Accessibility properties have no effect.
    public let isHidden: Bool
    /// A textual description of the node for use in system accessibility
    /// features such as VoiceOver. When used on an image, this label is
    /// used for what is commonly known as "alt text".
    public let label: String?
    /// Indicates to system accessibility features the order the node is
    /// presented to the user. For example the order read by VoiceOver.
    /// Nodes with higher values are presented before nodes with lower values.
    /// The default value is 0.
    public let sortPriority: Int?
    /// Indicates to system accessibility features such as VoiceOver that
    /// the node is a header that divides content into sections such as a
    /// section title. This enables features like VoiceOver to be able to
    /// quickly navigate between sections of content.
    public let isHeader: Bool
    ///  Setting this property on one node per screen enables system
    ///  accessibility features such as VoiceOver to provide the user with
    ///  a summary of the screen.
    public let isSummary: Bool
    ///  Indicates to system accessibility features such as VoiceOver that
    ///  interacting with this node will produce a sound.
    public let playsSound: Bool
    /// Indicates to system accessibility features such as VoiceOver that
    /// interacting with this node will begin playback of multimedia.
    public let startsMediaSession: Bool
    
    public init(isHidden: Bool, label: String?, sortPriority: Int?, isHeader: Bool, isSummary: Bool, playsSound: Bool, startsMediaSession: Bool) {
        self.isHidden = isHidden
        self.label = label
        self.sortPriority = sortPriority
        self.isHeader = isHeader
        self.isSummary = isSummary
        self.playsSound = playsSound
        self.startsMediaSession = startsMediaSession
    }
}
