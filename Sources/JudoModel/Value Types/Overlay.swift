import SwiftUI

@available(iOS 13.0, *)
public struct Overlay: Decodable {
    /// Background layer node
    public let node: Node

    /// The alignment of the background inside the resulting frame.
    public let alignment: Alignment

    public init(_ node: Node, alignment: Alignment = .center) {
        self.node = node
        self.alignment = alignment
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case node
        case alignment
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        node = try container.decodeNode(forKey: .node)
        alignment = try container.decode(Alignment.self, forKey: .alignment)
    }
}
