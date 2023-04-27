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
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @State var emailText = ""
    @State var passwordText = ""

    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image("BeatFluxLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40)
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                //ScrollView {

                    
                    HStack {
                        Text("Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.leading)
                    
                    
                    TextField(text: $emailText) {
                        Text("Email")
                            
                        
                    }
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .padding(.vertical)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    
                    SecureField(text: $passwordText) {
                        Text("Password")
                            
                        
                    }
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .padding(.vertical)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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
                    .padding(.bottom, keyboardObserver.keyboardHeight)
                    
                    .animation(.easeOut(duration: 0.25))
                    

                    
//                }
//                .scrollDisabled(false)
            }
            
        }
        
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
