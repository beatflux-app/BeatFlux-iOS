//
//  ContentView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/25/23.
//

import SwiftUI
import UIKit
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var isLoading = false
    @State private var displayAlert: Bool = false
    @State private var showForgotPasswordSheet = false
    
    private enum Field: Hashable {
        case email
        case password
    }
    
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
                    Text("Cancel")
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
                            .onAppear {
                                focusedField = .email
                            }
                            .disabled(isLoading)

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
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                authLogin()
                            }
                            .disabled(isLoading)
                    }
                    .padding(.horizontal)
                }

                
                
                Spacer()
                
                
                
                
                
            }
            .scrollDisabled(true)
            
            VStack {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showForgotPasswordSheet.toggle()
                } label: {
                    Text("Forgot Password?")
                        .fontWeight(.semibold)
                }
                .disabled(isLoading)

                
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    authLogin()
                } label: {
                    ZStack {
                        Rectangle()
                            .cornerRadius(30)
                            .frame(height: 50)
                            .padding(.horizontal)
                            .overlay {
                                Text("Login")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .opacity(isLoading ? 0 : 1)
                            }
                            
                        
                        LoadingIndicator(color: .white, lineWidth: 3)
                            .frame(width: 20, height: 20)
                            .opacity(isLoading ? 1 : 0)
                    }

                }
                .disabled(isLoading)
                .padding(.bottom)
            }
            
            

        }
        .alert(isPresented: $displayAlert) {
                    Alert(title: Text("Cannot Login"), message: Text(error), dismissButton: .default(Text("Ok")))
                }
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordView(showForgotPasswordSheet: $showForgotPasswordSheet)
        }

    }

    private func authLogin() {
        Task {
            isLoading = true
            
            do {
                try await AuthHandler.shared.loginUser(with: email, password: password)
            }
            catch AuthHandler.AuthResult.error(let error) {
                self.error = error
                displayAlert.toggle()
                
            }
            
            isLoading = false
            
        }
    }
}

private struct ForgotPasswordView: View {
    @Binding var showForgotPasswordSheet: Bool
    @State var emailToSendTo = ""
    @State var showPasswordResetAlert = false
    @State var passwordResetAlertText = ""
    @State var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {

        NavigationView {
            
            Form {
                Section {
                    Text("Email to send the password reset to")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(text: $emailToSendTo) {
                        Text("Email")
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                }

                
                Button {
                    if emailToSendTo.isEmpty {
                        passwordResetAlertText = "Please enter an email"
                        showPasswordResetAlert = true
                        return
                    }
                    
                    if !emailToSendTo.isValidEmail() {
                        passwordResetAlertText = "Please enter a valid email"
                        showPasswordResetAlert = true
                    }
                    
                    isLoading = true
                    
                    Auth.auth().sendPasswordReset(withEmail: emailToSendTo) { error in
                        if let error = error {
                            passwordResetAlertText = "Unable to send reset password email. Please try again later."
                            showPasswordResetAlert = true
                        }
                        else {
                            showForgotPasswordSheet = false
                        }
                        isLoading = false
                    }
                    
                    
                } label: {
                    HStack {
                        Text("Submit")
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                        }
                    }
                    
                }
                .disabled(isLoading)

            }
            .alert(passwordResetAlertText, isPresented: $showPasswordResetAlert, actions: {
                Button {
                    showPasswordResetAlert.toggle()
                } label: {
                    Text("Ok")
                }

            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    dismissButton
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Text("")
        }
        .buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(BeatFluxViewModel())
    }
}
