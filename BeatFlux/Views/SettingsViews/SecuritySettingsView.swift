//
//  SecuritySettingsView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/24/23.
//

import SwiftUI
import FirebaseAuth

struct SecuritySettingsView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var showChangePassword = false
    @State var isLoading = false
    @State var showBanner: Bool = false
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(imageIcon: Image(systemName: "tray.full.fill"),title: "Sent Email")

    
    var body: some View {
        Form {
            Section {
                NavigationLink(destination: ResetPasswordView(bannerData: $bannerData, showBanner: $showBanner)) {
                    Text("Change Password")
                }
                
                
                NavigationLink(destination: ForgotPasswordView(showBanner: $showBanner, bannerData: $bannerData)) {
                    Text("Forgot Password?")
                }

            }

        }
        .banner(data: $bannerData, show: $showBanner)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)


    }
    
    
   
}

private struct ForgotPasswordView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @State var email = ""
    @Environment(\.dismiss) var dismiss
    @State var isPasswordEmailResetLoading = false
    @State var passwordResetError = ""
    @State var showPasswordResetEmailError = false
    @State var showPasswordResetEmailSent = false
    @Binding var showBanner: Bool
    @Binding var bannerData: BannerModifier.BannerData

    
    var body: some View {
        Form {
            TextField("Email", text: $email)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .alert(passwordResetError, isPresented: $showPasswordResetEmailError, actions: {
            Button {
                showPasswordResetEmailError.toggle()
            } label: {
                Text("Ok")
            }
        })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                }

            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPasswordEmailResetLoading = true

                    if !email.isValidEmail() {
                        passwordResetError = "Please enter a valid email"
                        showPasswordResetEmailError = true
                        isPasswordEmailResetLoading = false
                        return
                    }
                    
                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                        isPasswordEmailResetLoading = false
                        if let error = error {
                            print("ERROR: Error sending password reset email: \(error.localizedDescription)")
                            passwordResetError = "Unable to send email. Please try again later."
                            showPasswordResetEmailError = true
                        }
                        else {
                            bannerData.title = "Email Sent"
                            bannerData.imageIcon = Image(systemName: "tray.full.fill")
                            showBanner = true
                            dismiss()
                        }
                    }
                    
                } label: {
                    if isPasswordEmailResetLoading {
                        ProgressView()
                    }
                    else {
                        Text("Send")
                            .fontWeight(.semibold)
                    }

                }
                .disabled(isPasswordEmailResetLoading)
            }
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

struct ResetPasswordView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var currentPassword = ""
    @State var newPassword = ""
    @State var confirmNewPassword = ""
    @State var showError = false
    @State var errorText = ""
    
    @State var isLoading = false
    
    @Binding var bannerData: BannerModifier.BannerData
    @Binding var showBanner: Bool
    
    
    var body: some View {
        
        Form {
            SecureField(text: $currentPassword) {
                Text("Current Password")
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            Section {
                SecureField(text: $newPassword) {
                    Text("New Password")
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                SecureField(text: $confirmNewPassword) {
                    Text("Confirm New Password")
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            } footer: {
                Text("Password must be 8 characters long")
            }
            
            

        }
        .alert(errorText, isPresented: $showError, actions: {
            Button {
                showError.toggle()
                errorText = ""
            } label: {
                Text("Ok")
            }
        })
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                }

            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isLoading = true
                    

                    if newPassword.isEmpty { errorText = "New password field is empty" }
                    
                    if currentPassword == newPassword {
                        errorText = "New password and old password are the same"
                    }
                    if confirmNewPassword.isEmpty { errorText = "Confirm new password field is empty" }
                    if newPassword.count < 8 { errorText = "New password must be 8 characters long" }

                    if currentPassword.isEmpty { errorText = "Password field is empty" }
                    if newPassword != confirmNewPassword {
                        errorText = "Passwords don't match"
                    }
                    
                    if !errorText.isEmpty {
                        showError = true
                        isLoading = false
                        return
                    }
                    
                    
                    reauthenticateUser(password: currentPassword)
                    
                    
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        else {
                            Text("Submit")
                                .fontWeight(.semibold)
                        }
                    }
                    
                }
                .disabled(isLoading)
            }
            
        }
        
        
        
    }
    
    func reauthenticateUser(password: String) {
        
        guard let usersCurrentEmail = beatFluxViewModel.user?.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: usersCurrentEmail, password: password)
        
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (authResult, error) in
            if let error = error {
                print("ERROR: Reauthentication error: \(error)")
                errorText = "Error while reauthenticating the user"
                showError = true
                isLoading = false
                return
            }
            Task {
                do {
                    try await beatFluxViewModel.changeUsersPassword(newPassword: newPassword)
                    isLoading = false
                }
                catch {
                    errorText = "Unable to change users password. Please try again later."
                    showError = true
                    print("ERROR: Unable to change users password \(error.localizedDescription)")
                    dismiss()
                    return
                }

                
                bannerData.title = "Changed Password"
                bannerData.imageIcon = Image(systemName: "key.icloud.fill")
                showBanner = true
                
                dismiss()
                
                
                
            }

            print("Successfully reauthenticated.")
            isLoading = false
            
        })

 
        
    
        
        
    }
    
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Text("")
        }
        .buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
    }
}


struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecuritySettingsView()
        }
        
    }
}
