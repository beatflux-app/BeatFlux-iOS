//
//  SettingsView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/31/23.
//

import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: ProfileSettingsView().environmentObject(beatFluxViewModel)) {
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
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.black)
                                .frame(width: 25, height: 25)
                                .overlay {
                                    Image("SpotifyLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18)
                                }
                            
                            Text("Spotify")
                        }
                    }
                    .disabled(!beatFluxViewModel.isUserValid || !beatFluxViewModel.isConnected)
                    
                } header: {
                    Text("Connections")
                }
                
                Section {
                    NavigationLink(destination: SecuritySettingsView()) {
                        HStack(spacing: 15) {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.blue)
                                .frame(width: 25, height: 25)
                                .overlay {
                                    Image(systemName: "lock.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            Text("Security")
                        }
                    }
                    .disabled(!beatFluxViewModel.isUserValid || !beatFluxViewModel.isConnected)
                    
                } header: {
                    Text("Settings")
                }

                
                
                
                Button {
                    AuthHandler.shared.signOut()
                } label: {
                    Text("Logout")
                }
                
                Section {
                    
                    
                    HStack {
                        Spacer()
                        VStack(spacing: 15) {
                            Image("BeatFluxLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Text("BeatFlux 0.1.0 (BETA)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                }
                .listRowBackground(Color.clear)


                
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
        SettingsView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
