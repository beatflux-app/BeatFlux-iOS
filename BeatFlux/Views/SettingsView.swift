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
                                    
                                    Text(beatFluxViewModel.userData?.first_name.isBlank == false ? beatFluxViewModel.userData?.first_name.prefix(1) ?? "?" : "?")
                                        .foregroundColor(.secondary)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                        
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Group {
                                    if beatFluxViewModel.isUserValid, let firstName = beatFluxViewModel.userData?.first_name, !firstName.isBlank {
                                        let lastName = beatFluxViewModel.userData?.last_name ?? ""
                                        Text("\(firstName) \(lastName)")
                                    } else {
                                        Text("Setup your profile")
                                    }
                                }
                                .foregroundColor(.primary)
                                .font(.headline)

                                Text(beatFluxViewModel.isUserValid ? "Edit user profile" : "No user found")
                                    .font(beatFluxViewModel.isUserValid ? .caption : .headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
 
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!beatFluxViewModel.isUserValid || !beatFluxViewModel.isConnected)
                    
                }
                
                Section {
                    NavigationLink(destination: SpotifySettingsView().environmentObject(beatFluxViewModel).environmentObject(spotify)) {
                        HStack(spacing: 15) {
                            Image("SpotifyLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25)
                            Text("Spotify")
                        }
                    }
                    .disabled(!beatFluxViewModel.isUserValid || !beatFluxViewModel.isConnected)
                    
                } header: {
                    Text("Connections")
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



private extension BeatFluxViewModel {
    var isUserValid: Bool {
        userData != nil && user != nil
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSettings: .constant(true))
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
