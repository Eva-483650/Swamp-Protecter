//
//  BackgroundView.swift
//  Space Invaders
//
//  Created by A on 2025/2/19.
//

import SwiftUI

struct BackgroundView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack{
            VStack{
                Text(#"In the foggy and gloomy swamp, the ferocious swamp python threatens the fragile ecosystem. The "Erosion Poison Flower" is the last line of defense. When the python nears, its petals shoot out with corrosive mucus and hallucinogenic toxins. As the player, you'll manipulate the power of the flower to repel the python and safeguard the swamp."#)
                    .foregroundColor(Color("AccentColor"))
                    .multilineTextAlignment(.center) // 左对齐
                    .lineSpacing(8)                   // 行间距
                    .padding(.horizontal, 36)          // 边距
                    .fixedSize(horizontal: false, vertical: true) //自动换行
                    .font(.title)
                
            }
            .padding(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/)
            .frame(width: 580, height: 400)
            .background(
                RoundedRectangle(cornerRadius:30).fill(Material.ultraThinMaterial)
            )
            .shadow(radius: 30)
            
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .padding(.top, 10)
                // 添加按压反馈
                .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: isShowing)
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isShowing = false
                    }
                }

        }
        }
}

#Preview {
    BackgroundView(isShowing: .constant(true))
}
