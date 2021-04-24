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

@available(iOS 13.0, *)
public struct Experience: Decodable {
    public enum Appearance: String, Decodable {
        case light
        case dark
        case auto
    }
    
    /// A unique identifier for the Experience.
    public let id: String
    public let name: String
    public let revisionID: String
    /// A set of nodes contained in the document. Use `initialScreenID` to determine the initial node to render.
    public let nodes: [Node]
    public let localization: StringTable
    /// Fonts download URLs
    public let fonts: [URL]
    /// The ID of the initial node to render.
    public let initialScreenID: Screen.ID
    public let appearance: Appearance

    public init(id: String, name: String, revisionID: String, nodes: [Node], localization: StringTable, fonts: [URL], initialScreenID: Screen.ID, appearance: Appearance) {
        self.id = id
        self.name = name
        self.revisionID = revisionID
        self.nodes = nodes
        self.initialScreenID = initialScreenID
        self.localization = localization
        self.fonts = fonts
        self.appearance = appearance
    }

    /// Initialize Experience from data (JSON)
    /// - Parameter data: Experience data.
    /// - Throws: Throws error on failure.
    public init(decode data: Data) throws {
        let decoder = JSONDecoder()
        let coordinator = DecodingCoordinator()
        decoder.userInfo[.decodingCoordinator] = coordinator
        self = try decoder.decode(Self.self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case revisionID
        case nodes
        case fonts
        case initialScreenID
        case localization
        case appearance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let revisionID = try container.decode(String.self, forKey: .revisionID)
        let name = try container.decode(String.self, forKey: .name)
        let initialScreenID = try container.decode(String.self, forKey: .initialScreenID)
        let localization = try container.decode(StringTable.self, forKey: .localization)
        let fonts = try container.decode([FontResource].self, forKey: .fonts)

        let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator

        let nodes = try container.decodeNodes(forKey: .nodes)
        coordinator.resolveRelationships(nodes: nodes)

        let fontURLs = fonts.map { $0.url }
        let appearance = try container.decode(Appearance.self, forKey: .appearance)
        self.init(id: id, name: name, revisionID: revisionID, nodes: nodes, localization: localization, fonts: fontURLs, initialScreenID: initialScreenID, appearance: appearance)
    }
}
