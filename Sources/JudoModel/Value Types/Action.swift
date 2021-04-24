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
public final class Action: Decodable {
    public enum ActionType: String, CaseIterable, Codable, CustomStringConvertible {
        case performSegue = "PerformSegueAction"
        case openURL = "OpenURLAction"
        case presentWebsite = "PresentWebsiteAction"
        case custom = "CustomAction"
        case close = "CloseAction"
        
        public var description: String {
            switch self {
            case .performSegue:
                return "Perform Segue"
            case .close:
                return "Close"
            case .custom:
                return "Custom"
            case .openURL:
                return "Open URL"
            case .presentWebsite:
                return "Present Website"
            }
        }
    }
    
    public let actionType: ActionType
    public var screen: Screen?
    public let segueStyle: SegueStyle?
    public let modalPresentationStyle: ModalPresentationStyle?
    public let url: String?
    public let dismissExperience: Bool?
    
    public init(actionType: ActionType, screen: Screen? = nil, segueStyle: SegueStyle? = nil, modalPresentationStyle: ModalPresentationStyle? = nil, url: String? = nil, dismissExperience: Bool? = nil) {    
        self.actionType = actionType
        self.screen = screen
        self.segueStyle = segueStyle
        self.modalPresentationStyle = modalPresentationStyle
        self.url = url
        self.dismissExperience = dismissExperience
    }
    
    // MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(actionType)
        hasher.combine(screen?.id)
        hasher.combine(segueStyle)
        hasher.combine(modalPresentationStyle)
        hasher.combine(url)
        hasher.combine(dismissExperience)
    }
    
    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.actionType == rhs.actionType
            && lhs.screen?.id == rhs.screen?.id
            && lhs.segueStyle == rhs.segueStyle
            && lhs.modalPresentationStyle == rhs.modalPresentationStyle
            && lhs.url == rhs.url
            && lhs.dismissExperience == rhs.dismissExperience
    }
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case screenID
        case segueStyle
        case modalPresentationStyle
        case url
        case dismissExperience
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        actionType = try container.decode(ActionType.self, forKey: .typeName)
        
        segueStyle = try container.decodeIfPresent(SegueStyle.self, forKey: .segueStyle)
        modalPresentationStyle = try container.decodeIfPresent(ModalPresentationStyle.self, forKey: .modalPresentationStyle)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        dismissExperience = try container.decodeIfPresent(Bool.self, forKey: .dismissExperience)

        if container.contains(.screenID) {
            let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
            let screenID = try container.decode(Node.ID.self, forKey: .screenID)
            coordinator.registerOneToOneRelationship(nodeID: screenID, to: self, keyPath: \.screen)
        }
    }
}
