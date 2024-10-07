//
//  ProfileView.swift
//  BlockScribe
//
//  Created by Alex Lin on 19/5/24.
//

import SwiftUI
import KindeSDK

struct Profile: Identifiable {
    let id = UUID()
    let name: String
    let type: ItemType
}

enum ItemType {
    case type1, type2, type3, type4, type5, type6
}

struct ProfileView: View {
    let TITLE_CLEAR_DATA = "Clear Data"
    let TITLE_LOG_OUT = "Log Out"
    let TITLE_DELETE_USER = "Delete Account"
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var presentAlert = false
    @State private var alertMessage = ""
    @State private var email: String?
    @State private var userId: String?
    @State private var showingImagePicker = false
    @State private var showingDefaultProfile = false
    @State private var image: UIImage?
    @State private var alertTitle = ""
    @State private var version = ""
    
    private let onLoggedOut: () -> Void
    private let logger: Logger?
    
    let items = [
        Profile(name: "FAQ", type: .type1),
        Profile(name: "Terms & Conditions", type: .type2),
        Profile(name: "Privacy Policy", type: .type3),
        //        Profile(name: "Clear Data", type: .type4),
        Profile(name: "Support", type: .type4),
        Profile(name: "Log Out", type: .type5),
        Profile(name: "Delete Account", type: .type6)
    ]
    
    init(logger: Logger?, onLoggedOut: @escaping () -> Void) {
        self.logger = logger
        self.onLoggedOut = onLoggedOut
        _email = State(initialValue: KindeSDKAPI.auth.getUserDetails()?.email)
        _userId = State(initialValue: KindeSDKAPI.auth.getUserDetails()?.id)
        print(_userId)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Divider()
                    .frame(height: 1)
                    .background(Color.gray)
                    .padding(.horizontal)
                
                ZStack{
                    image.map {
                        Image(uiImage: $0)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.clear, lineWidth: 1))
                            .onTapGesture {
                                showingImagePicker = true
                            }
                    }
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .foregroundColor(.purple)
                        .padding()
                        .opacity(showingDefaultProfile ? 1 : 0)
                        .onTapGesture {
                            showingImagePicker = true
                        }
                }
                Text(email ?? "")
                    .font(.title3)
                    .padding(.bottom, 10)
                Spacer()
                List(items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Button(action: {
                            handleButtonTap(for: item)
                        }) {}
                    }
                    .frame(height: 44)
                    .padding(.bottom, 10)
                }
                .listStyle(PlainListStyle())
                Spacer()
                VStack{
                    Text(self.version)
                        .font(.body)
                        .padding(.bottom, 20)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.automatic)
            .background(Color("MainBgColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("bs-logo-horizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, alignment: .leading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $image, showDefaultProfile: $showingDefaultProfile)
            }
        }
        .onAppear() {
            BSUtil.shared.updateColorScheme(colorScheme)
            Task {
                await loadProfileImage()
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                //                print("Version: \(version), Build: \(build)")
                self.version = "Current Version: v\(version).\(build)"
            }
        }
        .alert(isPresented: $presentAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text("Are you sure you want to proceed?"),
                primaryButton: .default(Text("Yes"), action: {
                    if (self.alertTitle == self.TITLE_LOG_OUT) {
                        self.logout()
                    } else {
                        Task {
                            let (data, response) = try await BSUtil.shared.deleteUser(userId: self.userId!)
                            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                                let code = json?["code"] as? String
                                if (code == "OK"){
                                    self.logout()
                                }
                            } else {
                                print("Failed to get token: HTTP status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                            }
                        }
                    }
                }),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func handleButtonTap(for item: Profile) {
        switch item.type {
        case .type1:
            BSUtil.shared.openURL("https://www.blockscribe.io/faqs-1")
        case .type2:
            BSUtil.shared.openURL("https://www.blockscribe.io?open=terms-and-conditions")
        case .type3:
            BSUtil.shared.openURL("https://www.blockscribe.io?open=privacy-policy")
            //        case .type4:
            //            alertTitle = self.TITLE_CLEAR_DATA
            //            presentAlert = true
        case .type4:
            self.openMailApp()
        case .type5:
            alertTitle = self.TITLE_LOG_OUT
            presentAlert = true
        case .type6:
            alertTitle = self.TITLE_DELETE_USER
            presentAlert = true
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(logger: nil){}
    }
}

extension ProfileView {
    func logout() {
        KindeSDKAPI.auth.logout { result in
            if result {
                self.onLoggedOut()
            } else {
                alertMessage = "Logout failed"
                self.logger?.error(message: alertMessage)
                presentAlert = true
            }
        }
    }
    
    func loadProfileImage() async {
        self.image = BSUtil.shared.loadProfileImage()
        self.showingDefaultProfile = self.image == nil;
    }
    
    func openMailApp() {
        let toEmail = "us@blockscribe.io"
        let email = toEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
