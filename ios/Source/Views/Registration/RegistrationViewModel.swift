//
// Copyright (C) 2021 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftCoroutine
import AppAuth

class RegistrationViewModel: ObservableObject {

    private var config: ApplicationConfig?
    private var state: ApplicationStateManager?
    private var appauth: AppAuthHandler?
    private var onRegistered: (() -> Void)?

    @Published var isLoaded: Bool
    @Published var error: ApplicationError?
    
    init() {

        self.config = nil
        self.state = nil
        self.appauth = nil
        self.onRegistered = nil
        self.error = nil
        self.isLoaded = false
    }

    func load(
        config: ApplicationConfig?,
        state: ApplicationStateManager,
        appauth: AppAuthHandler?,
        onRegistered: @escaping () -> Void) {
        
        self.config = config
        self.state = state
        self.appauth = appauth
        self.onRegistered = onRegistered
        self.isLoaded = true
    }

    /*
     * Lookup metadata and perform an initial login using the code flow and the DCR scope
     * Make HTTP requests on a worker thread and then perform updates on the UI thread
     */
    func startRegistration() {
        
        DispatchQueue.main.startCoroutine {

            do {

                // First get metadata
                self.error = nil
                var metadata: OIDServiceConfiguration? = nil
                try DispatchQueue.global().await {
                    metadata = try self.appauth!.fetchMetadata().await()
                }
                self.state!.metadata = metadata

                // Perform the code flow redirect for the initial sign in with a DCR scope
                let authorizationResponse = try self.appauth!.performAuthorizationRedirect(
                    metadata: metadata!,
                    clientID: self.config!.registrationClientID,
                    scope: "dcr",
                    viewController: self.getViewController(),
                    force: true
                ).await()

                if authorizationResponse != nil {

                    // Swap the code for a DCR access token
                    var dcrAccessToken: String? = ""
                    var tokenResponse: OIDTokenResponse? = nil
                    try DispatchQueue.global().await {

                        tokenResponse = try self.appauth!.redeemCodeForTokens(clientSecret: nil, authResponse: authorizationResponse!)
                            .await()
                    }
                    dcrAccessToken = tokenResponse?.accessToken
                    
                    // Then send the registration request, which is secured via the access token
                    var registrationResponse: OIDRegistrationResponse? = nil
                    try DispatchQueue.global().await {

                        registrationResponse = try self.appauth!.registerClient(metadata: metadata!, accessToken: dcrAccessToken!)
                            .await()
                    }
                    self.state!.saveRegistration(registrationResponse: registrationResponse!)

                    // Tell the main view to update
                    self.onRegistered!()
                }

            } catch {

                let appError = error as? ApplicationError
                if appError != nil {
                    self.error = appError!
                }
            }
        }
    }
    
    private func getViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}

