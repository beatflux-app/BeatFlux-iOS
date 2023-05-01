//
//  ContentView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/25/23.
//

import SwiftUI
import UIKit
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authHandler: AuthHandler
    
    enum Field: Hashable {
        case email
        case password
    }

    @State var email = ""
    @State var password = ""
    @FocusState var focusedField: Field?
    @State var error = ""
    
    @State var displayAlert: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Image("BeatFluxLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .fontWeight(.bold)
                    
                }
                .padding(.leading)

            }
            .padding(.top)
            
            ScrollView {
                
                HStack {
                    Text("Login to your account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding([.leading, .bottom])

                VStack(spacing: 25) {
                    //MARK: Email
                    AuthTextLabel_Element(text: email, placeholderText: "Email") {
                        TextField("", text: $email)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding(.horizontal)

                    //MARK: Password
                    AuthTextLabel_Element(text: password, placeholderText: "Password") {
                        SecureField("", text: $password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                //auth code here
                            }
                    }
                    .padding(.horizontal)
                }

                
                
                Spacer()
                
                
                
                
                
            }
            .scrollDisabled(true)
            
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                Task {
                    do {
                        let _ = try await authHandler.loginUser(with: email, password: password)
                    }
                    catch AuthHandler.AuthResult.error(let error) {
                        print("Error: \(error)")
                        self.error = error
                        displayAlert.toggle()
                    }
                    
                }
            } label: {
                Rectangle()
                    .cornerRadius(30)
                    .frame(height: 50)
                    .padding(.horizontal)
                    .overlay {
                        Text("Login")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
            }
            .padding(.bottom)

        }
        .alert(isPresented: $displayAlert) {
                    Alert(title: Text("Cannot Login"), message: Text(error), dismissButton: .default(Text("Ok")))
                }

    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authHandler: AuthHandler())
    }
}
