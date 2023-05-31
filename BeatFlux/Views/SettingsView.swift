//
//  SettingsView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/31/23.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: Text("TEST")) {
                        HStack(spacing: 15) {
                            Circle()
                                .frame(height: 55)
                                .foregroundColor(Color(UIColor.secondarySystemFill))
                                .overlay {
                                    
                                    Text(beatFluxViewModel.userData?.first_name.prefix(1) ?? "?")
                                        .foregroundColor(.secondary)
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            

                            if let userData = beatFluxViewModel.userData, let _ = beatFluxViewModel.user {
                                VStack(alignment: .leading, spacing: 2) {
                                    Group {
                                        if (!userData.first_name.isEmpty && userData.first_name != " ") {
                                            Text(userData.first_name + " " + userData.last_name)
                                        }
                                        else if let email = userData.email {
                                            Text(email)
                                        }
                                        else {
                                            Text("Setup your profile")
                                        }
                                    }
                                    .foregroundColor(.primary)
                                    .font(.headline)

                                    Text("Edit user profile")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                
                            }
                            else {
                                Text("No user found")
                            }
                            
                            Spacer()
                            
                            
                            
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        //.background(Color(UIColor.tertiarySystemFill))
//                        .cornerRadius(20)

                    }
                    .disabled((beatFluxViewModel.userData == nil) && (beatFluxViewModel.user == nil))
                }
                
                
                Button {
                    AuthHandler.shared.signOut()
                } label: {
                    Text("Logout")
                }

                
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Text("Done")
                            .fontWeight(.bold)
                    }

                    
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSettings: .constant(true))
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
