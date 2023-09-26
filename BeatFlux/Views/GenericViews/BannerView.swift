//
//  BannerView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/19/23.
//

import SwiftUI
struct BannerModifier: ViewModifier {
    
    struct BannerData {
        var imageIcon: Image
        var title: String
    }
    
    @Binding var data: BannerData
    @Binding var show: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        data.imageIcon
                        Text(data.title)
                            .font(.subheadline)
                            .bold()
                    }
                    .foregroundColor(Color.white)
                    .padding(12)
                    .background(Material.bar)
                    .cornerRadius(8)
                }
                .padding()
                .transition(AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity))
                .offset(y: show ?  0: 300)
                .animation(.easeInOut(duration: 0.4), value: show)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        show = false
                    }
                }
                .onChange(of: show) { value in
                    if value == true {
                        withAnimation {
                            self.show = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.show = false
                            }
                        }
                    }
                }
            
        }
    }
}

extension View {
    func banner(data: Binding<BannerModifier.BannerData>, show: Binding<Bool>) -> some View {
        self.modifier(BannerModifier(data: data, show: show))
    }
}
