import Foundation

public enum FontResource: Decodable {
    case fontResource(url: URL, fontName: String)
    case fontResourceCollection(url: URL, fontNames: [String])

    public var url: URL {
        switch self {
            case .fontResource(let url, _):
                return url
            case .fontResourceCollection(let url, _):
                return url
        }
    }

    enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case url
        case fontName
        case fontNames
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .typeName)
        switch typeName {
            case "FontResource":
                let url = try container.decode(URL.self, forKey: .url)
                let fontName = try container.decode(String.self, forKey: .fontName)
                self = .fontResource(url: url, fontName: fontName)
            case "FontCollectionResource":
                let url = try container.decode(URL.self, forKey: .url)
                let fontNames = try container.decode([String].self, forKey: .fontNames)
                self = .fontResourceCollection(url: url, fontNames: fontNames)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .typeName,
                    in: container,
                    debugDescription: "Invalid value: \(typeName)"
                )
            }
        }
    }
