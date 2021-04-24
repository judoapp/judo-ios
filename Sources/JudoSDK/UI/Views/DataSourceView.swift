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
import Combine
import SwiftUI

@available(iOS 13.0, *)
struct DataSourceView: View {
    var dataSource: JudoModel.DataSource
    @Environment(\.data) private var parentData
    @Environment(\.userInfo) private var userInfo
    
    @State private var cancellables: Set<AnyCancellable> = []

    // Fetched data
    @State private var fetchedData: JSONObject?

    @ViewBuilder
    var body: some View {
        if let fetchedData = fetchedData {
            ForEach(layers) {
                LayerView(layer: $0)
            }
            .environment(\.data, fetchedData)
            .onReceive(dataSource.objectWillChange) {
                cancellables.removeAll()
                publisher.sink { result in
                    guard case let Result.success(fetchedData) = result else {
                        return
                    }
                    self.fetchedData = fetchedData
                }.store(in: &cancellables)
            }
        } else {
            redactedView
                .onReceive(publisher) { result in
                    guard case let Result.success(fetchedData) = result else {
                        return
                    }
                    self.fetchedData = fetchedData
                }
        }
    }
    
    private var publisher: AnyPublisher<Result<JSONObject, Error>, Never> {
        guard let urlString = dataSource.url.evaluatingExpressions(data: parentData, userInfo: userInfo), let url = URL(string: urlString) else {
            return Just(Result.failure(UnableToInterpolateDataSourceURLError())).eraseToAnyPublisher()
        }
        
        let request = URLRequest(
            url: url,
            httpMethod: dataSource.httpMethod,
            httpBody: dataSource.httpBody,
            headers: dataSource.headers
        )
        
        return URLSession.shared.dataPublisher(
            for: request
        )
    }
    
    private var layers: [Layer] {
        dataSource.children.compactMap { $0 as? Layer }
    }
    
    @ViewBuilder
    private var redactedView: some View {
        if #available(iOS 14.0, *) {
            ForEach(layers) {
                LayerView(layer: $0)
            }
            .redacted(reason: .placeholder)
        } else {
            // TODO: Anything better we can do here?
            EmptyView()
        }
    }
}

private struct UnableToInterpolateDataSourceURLError: Error {
    var errorDescription: String {
        "Unable to evaluate expressions in Data Source URL"
    }
}
