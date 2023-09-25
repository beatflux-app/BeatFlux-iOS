//
//  ProfileSettingsView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/4/23.
//

import SwiftUI
import FirebaseAuth

struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @State private var originalFirstName: String = "" {
        didSet { firstName = originalFirstName }
    }
    @State private var originalLastName: String = "" {
        didSet { lastName = originalLastName }
    }
    @State private var originalEmail: String = "" {
        didSet { email = originalEmail }
    }
    
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var email: String = ""
    @State var isLoading: Bool = false
    @State var showConfirmationToCancel = false
    @State private var isReauthenticationViewPresented: Bool = false
    @State var showPasswordError = false
    @State var showError: Bool = false
    @State var error: String = ""
    @State var password: String = ""
    
    @FocusState private var focusedField: Field?
    
    @State var didChangeProfile: Bool = false
    
    private enum Field: Hashable {
        case firstName
        case lastName
        case email
    }
    

    
    var body: some View {
        Form {
            Section {
                
                HStack {
                    Spacer()
                    
                    Circle()
                        .frame(height: 70)
                        .foregroundColor(Color(UIColor.secondarySystemFill))
                        .overlay {
                            
                            Text(!firstName.isBlank ? firstName.prefix(1) : "?")
                                .foregroundColor(.secondary)
                                .font(.title)
                                .fontWeight(.bold)
                            
                                
                    }
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listStyle(PlainListStyle())

            
            Section {
                
                HStack {
                    Text("Name")
                        .fontWeight(.semibold)
                    Divider()
                    TextField("First" ,text: $firstName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .firstName)
                        .onChange(of: firstName, perform: { newValue in checkForModifiedValues() })
                        .onSubmit {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            focusedField = .lastName
                        }
                        .disabled(isLoading)
                    
                    TextField("Last" ,text: $lastName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .lastName)
                        .onChange(of: lastName, perform: { newValue in checkForModifiedValues() })
                        .onSubmit {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            focusedField = .email
                        }
                        .disabled(isLoading)
                }
                
                HStack {
                    Text("Email ")
                        .fontWeight(.semibold)
                    Divider()
                    TextField("Email" ,text: $email)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .email)
                        .onChange(of: email, perform: { newValue in checkForModifiedValues() })
                        .onSubmit {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        }
                        .disabled(isLoading)
                }
                
            }
        }
        .onAppear {
            
            if let userData = beatFluxViewModel.userData {
                originalFirstName = userData.first_name
                originalLastName = userData.last_name
                originalEmail = beatFluxViewModel.user?.email ?? ""
            }
            
        }
        .alert(error, isPresented: $showError, actions: {
            Button {
                showError.toggle()
            } label: {
                Text("Ok")
            }
        })
        .alert("Are you sure you want to discard your changes?", isPresented: $showConfirmationToCancel, actions: {
            Button {
                showConfirmationToCancel.toggle()
            } label: {
                Text("Cancel")
            }
            
            Button {
                dismiss()
            } label: {
                Text("Confirm")
            }

        })
        .sheet(isPresented: $isReauthenticationViewPresented, onDismiss: {
            isLoading = false
        }, content: {
            NavigationView {
                Form {

                    Section {
                        Text("Please re-enter your password to continue")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        SecureField("Password", text: $password)
                    }

                    Button("Submit") {
                        
                        reauthenticateUser(email: email, password: password)
                       
                        
                    }
                    .alert(isPresented: $showPasswordError) {
                        Alert(
                            title: Text("Error"),
                            message: Text("Could not reauthenticate. Please try again."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                        
                        
                    
                }
                .navigationTitle("Reauthenticate")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isLoading = false
                            isReauthenticationViewPresented = false
                        } label: {
                            dismissButton
                        }

                    }

                }
            }
        })

        
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem {
                if beatFluxViewModel.isConnected {
                    Button {
                        Task {
                            await saveProfile()
                        }
                        
                        
                    } label: {
                        if isLoading {
                            ProgressView()
                        }
                        else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }

                    }
                    .disabled(!didChangeProfile)
                }
                else {
                    LoadingIndicator()
                }
                
                

            }
        }
        
    }
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Text("")
        }
        .buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
    }
    
    private func reauthenticateUser(email: String, password: String) {
        
        guard let usersCurrentEmail = beatFluxViewModel.user?.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: usersCurrentEmail, password: password)
        
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (authResult, error) in
            if let error = error {
                print("Reauthentication error: \(error)")
                showPasswordError = true
                return
            }
            Task {
                do {
                    try await beatFluxViewModel.changeUsersEmail(newEmail: email)
                }
                catch {
                    print(error.localizedDescription)
                }
                beatFluxViewModel.userData?.first_name = firstName
                beatFluxViewModel.userData?.last_name = lastName

                await beatFluxViewModel.uploadUserData()
                isLoading = false
                dismiss()
                
            }
            
            isReauthenticationViewPresented = false
            print("Successfully reauthenticated.")
            
        })

 
        
    
        
        
    }
    
    func checkForModifiedValues() {
        if email != originalEmail || firstName != originalFirstName || lastName != originalLastName {
            didChangeProfile = true
        }
        else {
            didChangeProfile = false
        }
    }
    
    func saveProfile() async {
        error = ""
        if email.isBlank { error = "Email is blank" }
        if firstName.isBlank { error = "First name is blank" }
        if lastName.isBlank { error = "Last name is blank" }
        if !email.isValidEmail() { error = "Email is not valid" }
        isLoading = true
        
        if !error.isBlank {
            showError = true
            isLoading = false
            return
        }
        
        
        if email != beatFluxViewModel.user?.email {
            isReauthenticationViewPresented = true
        }
        else {
            beatFluxViewModel.userData?.first_name = firstName
            beatFluxViewModel.userData?.last_name = lastName

            
            Task {
                await beatFluxViewModel.uploadUserData()
                isLoading = false
                dismiss()
            }
        }
        
    }
}



struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSettingsView()
                .environmentObject(BeatFluxViewModel())
        }
    }
}
