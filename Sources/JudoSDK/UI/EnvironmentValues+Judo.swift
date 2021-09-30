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

import JudoModel
import SwiftUI
import os.log

@available(iOS 13.0, *)
internal struct ExperienceKey: EnvironmentKey {
    static let defaultValue: Experience? = nil
}

@available(iOS 13.0, *)
internal struct ScreenKey: EnvironmentKey {
    static let defaultValue: Screen? = nil
}

@available(iOS 13.0, *)
internal struct StringTableKey: EnvironmentKey {
    static let defaultValue: StringTable = StringTable()
}

@available(iOS 13.0, *)
internal struct PresentActionKey: EnvironmentKey {
    static let defaultValue: (UIViewController) -> Void = {
        _ in
        judo_log(.error, "Present action was ignored.")
    }
}

@available(iOS 13.0, *)
internal struct ShowActionKey: EnvironmentKey {
    static let defaultValue: (UIViewController) -> Void = {
        _ in
        judo_log(.error, "Show action was ignored.")
    }
}

@available(iOS 13.0, *)
internal struct ScreenViewControllerKey: EnvironmentKey {
    static let defaultValue: ScreenViewController? = nil
}

@available(iOS 13.0, *)
internal struct ExperienceViewControllerKey: EnvironmentKey {
    static let defaultValue: ExperienceViewController? = nil
}

@available(iOS 13.0, *)
internal struct DataKey: EnvironmentKey {
    static let defaultValue: Any? = nil
}

@available(iOS 13.0, *)
internal struct URLParametersKey: EnvironmentKey {
    static let defaultValue: [String: String] = [:]
}

@available(iOS 13.0, *)
internal struct UserInfoKey: EnvironmentKey {
    static let defaultValue: [String: Any] = [:]
}

@available(iOS 13.0, *)
internal struct AuthorizeKey: EnvironmentKey {
    static let defaultValue: (inout URLRequest) -> Void = { _ in }
}

@available(iOS 13.0, *)
internal struct CollectionIndexKey: EnvironmentKey {
    static var defaultValue = 0
}

@available(iOS 13.0, *)
internal extension EnvironmentValues {
    var experience: Experience? {
        get {
            self[ExperienceKey.self]
        }
        
        set {
            self[ExperienceKey.self] = newValue
        }
    }
    
    var screen: Screen? {
        get {
            self[ScreenKey.self]
        }
        
        set {
            self[ScreenKey.self] = newValue
        }
    }
    
    var stringTable: StringTable {
        get {
            self[StringTableKey.self]
        }
        
        set {
            self[StringTableKey.self] = newValue
        }
    }

    var presentAction: ((UIViewController) -> Void) {
        get {
            self[PresentActionKey.self]
        }
        
        set {
            self[PresentActionKey.self] = newValue
        }
    }

    var showAction: ((UIViewController) -> Void) {
        get {
            self[ShowActionKey.self]
        }
        
        set {
            self[ShowActionKey.self] = newValue
        }
    }

    var screenViewController: ScreenViewController? {
        get {
            self[ScreenViewControllerKey.self]
        }
        
        set {
            self[ScreenViewControllerKey.self] = newValue
        }
    }
 
    var experienceViewController: ExperienceViewController? {
        get {
            self[ExperienceViewControllerKey.self]
        }
        
        set {
            self[ExperienceViewControllerKey.self] = newValue
        }
    }
    
    var data: Any? {
        get {
            return self[DataKey.self]
        }
        
        set {
            self[DataKey.self] = newValue
        }
    }
    
    var urlParameters: [String: String] {
        get {
            return self[URLParametersKey.self]
        }
        
        set {
            self[URLParametersKey.self] = newValue
        }
    }
    
    var userInfo: [String: Any] {
        get {
            return self[UserInfoKey.self]
        }
        
        set {
            self[UserInfoKey.self] = newValue
        }
    }
    
    var authorize: (inout URLRequest) -> Void {
        get {
            return self[AuthorizeKey.self]
        }
        
        set {
            self[AuthorizeKey.self] = newValue
        }
    }
    
    var collectionIndex: Int {
        get {
            return self[CollectionIndexKey.self]
        }
        
        set {
            self[CollectionIndexKey.self] = newValue
        }
    }
}
