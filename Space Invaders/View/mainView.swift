//
//  mainView.swift
//  Space Invaders
//
//  Created by A on 2025/2/20.
//

import SwiftUI

struct mainView: View {
    enum GameState {
        case start
        case playing
    }
    @State private var currentState: GameState = .start
    var body: some View {
        ZStack {
                    switch currentState {
                    case .start:
                        StartView(currentState: $currentState)
                            .transition(.opacity)
                        
                    case .playing:
                        // 现在可以正确传递参数
                        ContentView(currentState: $currentState)
                            .transition(.opacity)
                    }
                }
        .animation(.easeInOut, value: currentState) // 统一添加动画
    }
}

#Preview {
    mainView()
}
