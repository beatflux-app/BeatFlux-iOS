//
//  WelcomePageView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/28/23.
//

import SwiftUI

struct WelcomePageView: View {
    @EnvironmentObject var databaseHandler: DatabaseHandler
    @EnvironmentObject var authHandler: AuthHandler
    @State var loginPageShowing: Bool = false
    @State var signupPageShowing: Bool = false
    
    var body: some View {
        //MARK: Home Page
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
            
            Spacer()
            
            Text("Backup your playlists in real time.")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.horizontal)
            
            Spacer()
            
            
            VStack(spacing: 20) {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                   
                } label: {
                    Rectangle()
                        .cornerRadius(30)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .border(.secondary, width: 0.5, cornerRadius: 30)
                        
                        .overlay {
                            Text("Sign In With Apple")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .overlay(alignment: .leading) {
                                    Image("AppleLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 25)
                                        .padding(.leading)
                                }
                            
                        }
                        .padding(.horizontal)
                }
                
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } label: {
                    Rectangle()
                        .cornerRadius(30)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .border(.secondary, width: 0.5, cornerRadius: 30)
                        
                        .overlay {
                            Text("Sign In With Google")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .overlay(alignment: .leading) {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 25)
                                        .padding(.leading)
                                }
                            
                        }
                        .padding(.horizontal)
                }

            }
            .padding(.bottom)
            
            HStack {
                Rectangle()
                    .frame(height: 1)
                Text("OR")
                    .font(.caption)
                Rectangle()
                    .frame(height: 1)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.bottom)
            
            VStack(spacing: 20) {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    loginPageShowing.toggle()
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
                .fullScreenCover(isPresented: $loginPageShowing) {
                    LoginView()
                        .environmentObject(authHandler)
                        .environmentObject(databaseHandler)
                }
                
                
                Button {
                    signupPageShowing.toggle()
                } label: {
                    Group {
                        Text("Don't have an accout? ")
                            
                        +
                        
                        Text("Sign Up!")
                            
                    }
                    .fontWeight(.semibold)
                }
                .fullScreenCover(isPresented: $signupPageShowing) {
                    SignupView()
                        .environmentObject(authHandler)
                        .environmentObject(databaseHandler)
                }
            }
            .padding(.bottom)
            
            
            
        }
    }
}

struct WelcomePageView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomePageView()
            .environmentObject(AuthHandler())
    }
}
