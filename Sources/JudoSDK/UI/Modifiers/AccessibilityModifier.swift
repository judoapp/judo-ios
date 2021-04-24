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
import JudoModel

@available(iOS 13.0, *)
struct AccessibilityModifier: ViewModifier {
    var node: Node
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let accessibility = node.accessibility {
            if accessibility.isHidden {
                content.accessibility(hidden: true)
            } else {
                content
                    .modifier(
                        LabelModifier(accessibility: accessibility)
                    )
                    .modifier(
                        SortPriorityModifier(accessibility: accessibility)
                    )
                    .modifier(
                        TraitsModifier(accessibility: accessibility)
                    )
            }
        } else {
            content
        }
    }
}

@available(iOS 13.0, *)
private struct LabelModifier: ViewModifier {
    var accessibility: Accessibility
    
    @Environment(\.data) private var data
    @Environment(\.stringTable) private var stringTable
    @Environment(\.userInfo) private var userInfo
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let label = accessibility.label, let textValue = stringTable.resolve(key: label).evaluatingExpressions(data: data, userInfo: userInfo) {
            content.accessibility(label: Text(textValue))
        } else {
            content
        }
    }
}

@available(iOS 13.0, *)
private struct SortPriorityModifier: ViewModifier {
    var accessibility: Accessibility
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let sortPriority = accessibility.sortPriority {
            content.accessibility(sortPriority: Double(sortPriority))
        } else {
            content
        }
    }
}

@available(iOS 13.0, *)
private struct TraitsModifier: ViewModifier {
    var accessibility: Accessibility
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if accessibilityTraits != [] {
            content.accessibility(addTraits: accessibilityTraits)
        } else {
            content
        }
    }
    
    private var accessibilityTraits: AccessibilityTraits {
        var result = AccessibilityTraits()
        
        if accessibility.isHeader {
            result.formUnion(.isHeader)
        }
        
        if accessibility.isSummary {
            result.formUnion(.isSummaryElement)
        }
        
        if accessibility.playsSound {
            result.formUnion(.playsSound)
        }
        
        if accessibility.startsMediaSession {
            result.formUnion(.startsMediaSession)
        }
        
        return result
    }
}
