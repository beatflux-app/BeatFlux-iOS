//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/23/23.
//

import SwiftUI
import Foundation
import FirebaseCore
import FirebaseFirestore
import Network
import FirebaseAuth


class BeatFluxViewModel: ObservableObject {
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkManager")
    
    @Published var isViewModelFullyLoaded: Bool = false
    @Published var isConnected = true
    @Published var isUserLoggedIn: Bool = false {
        didSet {
            
            DispatchQueue.main.async {
                self.userData = nil
                self.isViewModelFullyLoaded = false
//                Task { [weak self] in
//                    await self?.uploadUserData()
//                    
//                }
            }
            
            Task {
                if self.isUserLoggedIn {
                    await self.loadUserData()
                }
            }
            
            
        }
    }
    @Published var userData: UserModel? //{
//        didSet {
//            Task {
//                do {
//                    if userData != nil && isViewModelFullyLoaded {
//                        try await uploadUserData()
//                    }
//                    
//                } catch {
//                    print("ERROR: Failed to upload user data: \(error.localizedDescription)")
//                }
//            }
//        }
    //}


    
    
    enum UserError: Error {
        case nilUserData
    }
    
    var user: User? {
        return Auth.auth().currentUser
    }
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.cellular) {
                        withAnimation(.none) {
                            self.isConnected = true
                        }
                        
                    } else {
                        withAnimation(.none) {
                            self.isConnected = false
                        }
                    }
                }
                else {
                    withAnimation(.none) {
                        self.isConnected = false
                    }
                }
                
            }
        }
        
        monitor.start(queue: queue)
        
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let _ = user {
                self.isUserLoggedIn = true
            } else {
                self.isUserLoggedIn = false
            }
        }
        
    }

    // Call this function once the user is signed in/up
    func loadUserData() async {
        await retrieveUserData()
        DispatchQueue.main.async {
            self.isViewModelFullyLoaded = true
        }
    }
    


    func retrieveUserData() async {
        do {
            let data = try await DatabaseHandler.shared.getUserData()
            DispatchQueue.main.async {
                self.userData = data
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.uploadUserData()
                    
                }
            }
            
        }
        catch {
            print("ERROR: Failed to retrieve user data: \(error.localizedDescription)")
        }

    }
    
    func uploadUserData() async{
        guard let userData = userData else {
            print("ERROR: User data is nil")
            return
        }
        
        do {
            try await DatabaseHandler.shared.uploadUserData(from: userData)
        }
        catch {
            print("ERROR: Failed to upload user data: \(error.localizedDescription)")
        }
    }
}
