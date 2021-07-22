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

import UIKit

struct EventPayload {
    var id = UUID()
    var timestamp = Date()
    var anonymousID: String
    var userID: String?
    var event: Event
    var context: EventContext
    
    init(anonymousID: String, userID: String? = nil, event: Event, context: EventContext) {
        self.anonymousID = anonymousID
        self.userID = userID
        self.event = event
        self.context = context
    }
}

extension EventPayload: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case anonymousID
        case userID
        case type
        case traits
        case properties
        case context
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        anonymousID = try container.decode(String.self, forKey: .anonymousID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "register":
            event = .register
        case "identify":
            let traits = try container.decode(JSON.self, forKey: .traits)
            event = .identify(traits: traits)
        case "screen":
            let properties = try container.decode(JSON.self, forKey: .properties)
            event = .screen(properties: properties)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid value: \(type)"
            )
        }
        
        context = try container.decode(EventContext.self, forKey: .context)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(anonymousID, forKey: .anonymousID)
        try container.encodeIfPresent(userID, forKey: .userID)
        
        switch event {
        case .register:
            try container.encode("register", forKey: .type)
        case .identify(let traits):
            try container.encode("identify", forKey: .type)
            try container.encode(traits, forKey: .traits)
        case .screen(let properties):
            try container.encode("screen", forKey: .type)
            try container.encode(properties, forKey: .properties)
        }
        
        try container.encode(context, forKey: .context)
    }
}

enum Event: CustomStringConvertible {
    case register
    case identify(traits: JSON?)
    case screen(properties: JSON)
    
    var description: String {
        switch self {
        case .register:
            return "register"
        case .identify:
            return "identify"
        case .screen:
            return "screen"
        }
    }
}

struct EventContext: Codable {
    struct Device: Codable {
        var id: String
        var token: String?
        var buildEnvironment: BuildEnvironment
        
        init(token: String?) {
            self.id = UIDevice.current.identifierForVendor?.uuidString ?? ""
            self.token = token
            self.buildEnvironment = _buildEnvironment
        }
    }
    
    struct OperatingSystem: Codable {
        var name: String
        var version: String
        
        init() {
            name = "iOS"
            version = UIDevice.current.systemVersion
        }
    }
    
    var device: Device
    var os: OperatingSystem
    var locale: String
    
    init(deviceToken: String?) {
        device = Device(token: deviceToken)
        os = OperatingSystem()
        locale = Locale.preferredLanguages.first ?? "" // Locale.current.identifier
    }
}

// This work only needs to be done once.
private let _buildEnvironment = BuildEnvironment()

enum BuildEnvironment: String, Codable {
    case production = "PRODUCTION"
    case development = "DEVELOPMENT"
    case simulator = "SIMULATOR"
    
    init() {
        #if targetEnvironment(simulator)
        self = .simulator
        #else
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            judo_log(.error, "Provisioning profile not found")
            self = .production
            return
        }
        
        guard let embeddedProfile = try? String(contentsOfFile: path, encoding: String.Encoding.ascii) else {
            judo_log(.error, "Failed to read provisioning profile at path: %@", path)
            self = .production
            return
        }
        
        let scanner = Scanner(string: embeddedProfile)
        var string: NSString?
        
        guard scanner.scanUpTo("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", into: nil), scanner.scanUpTo("</plist>", into: &string) else {
            judo_log(.error, "Unrecognized provisioning profile structure")
            self = .production
            return
        }
        
        guard let data = string?.appending("</plist>").data(using: String.Encoding.utf8) else {
            judo_log(.error, "Failed to decode provisioning profile")
            self = .production
            return
        }
        
        guard let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] else {
            judo_log(.error, "Failed to serialize provisioning profile")
            self = .production
            return
        }
        
        guard let entitlements = plist["Entitlements"] as? [String: Any], let apsEnvironment = entitlements["aps-environment"] as? String else {
            judo_log(.info, "No entry for \"aps-environment\" found in Entitlements – defaulting to production")
            self = .production
            return
        }
        
        self = .init(rawValue: apsEnvironment.uppercased()) ?? .production
        #endif
    }
}
