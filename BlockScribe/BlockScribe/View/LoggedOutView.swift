//
//  LoggedOutView.swift
//  BlockScribe
//
//  Created by Alex Lin on 9/3/24.
//

import Foundation
import SwiftUI
import KindeSDK

struct LoggedOutView: View {
    @State private var presentAlert = false
    @State private var alertMessage = ""
    
    private let logger: Logger?
    private let onLoggedIn: () -> Void
    private let auth: Auth = KindeSDKAPI.auth
    
    init(logger: Logger?, onLoggedIn: @escaping () -> Void) {
        self.logger = logger
        self.onLoggedIn = onLoggedIn
    }
    
    var body: some View {
        VStack {
            VStack {
                VStack{
                    Image("bs-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120, alignment: .center)
                    
                    Image("welcome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    
                    Text("Welcome")
                        .font(.largeTitle)
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                    
                    Button(action: {
                        self.login()
                    }){
                        Text("Login")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .background(.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)

                    Button(action: {
                        self.register()
                    }){
                        Text("Sign Up")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .background(.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                }
                Spacer()
            }
        }
        .alert(Text("Error"), isPresented: $presentAlert) {
            Button("OK") {
                presentAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
}

struct LoggedOutView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedOutView(logger: nil) {}
    }
}

extension LoggedOutView {
    func register() {
        auth.register { result in
            switch result {
            case let .failure(error):
                if !auth.isUserCancellationErrorCode(error) {
                    alertMessage = "Registration failed: \(error.localizedDescription)"
                    self.logger?.error(message: alertMessage)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentAlert = true
                    }
                }
            case .success:
                self.onLoggedIn()
            }
        }
    }
    
    func login() {
        auth.login { result in
            switch result {
            case let .failure(error):
                if !auth.isUserCancellationErrorCode(error) {
                    alertMessage = "Login failed: \(error.localizedDescription)"
                    self.logger?.error(message: alertMessage)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentAlert = true
                    }
                }
            case .success:
                self.onLoggedIn()
            }
        }
    }
}

