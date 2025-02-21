//
//  StartView.swift
//  Space Invaders
//
//  Created by A on 2025/2/19.
//

import SwiftUI
import AVFAudio

struct StartView: View {
    @State var isShowingBG = false
    @Binding var currentState: mainView.GameState
    @State private var bgmPlayer: AVAudioPlayer?
    var body: some View {
            ZStack{
                Image("back")
                    .resizable()
                    .scaledToFill() // 保持比例填满
                    .ignoresSafeArea()
                
                if isShowingBG {
                       Rectangle()
                           .fill(.ultraThinMaterial)
                           .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                   }
                   
                VStack(spacing:40){
                    VStack(spacing:30)
                    {
                        Text("Swamp Protector")
                            .lilacTitle()
                        Text("Are you ready to battle the swamp python?")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.accentColor)
                    
                        Button {
                            currentState = .playing
                            SoundManager.instance.playSound(sound: .bubbleSound)
                        } label: {
                            PrimaryButton(text: "Let's go!")
                                .padding(.bottom, -15.0)
                                .font(.system(size: 26))
                        }
                        Button{
                            isShowingBG = true
                            SoundManager.instance.playSound(sound: .bubbleSound)
                        }label: {
                            PrimaryButton(text: "Game Background")
                                .padding(.bottom, -15.0)
                                .font(.system(size: 26))
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity,maxHeight:.infinity)
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    if isShowingBG {
                        GeometryReader { geometry in
                            Color.clear // 作为定位锚点
                                .overlay(
                                    BackgroundView(isShowing: $isShowingBG)
                                        .frame(width: min(geometry.size.width * 0.8, 600)) // 动态宽度限制
                                        .position(x: geometry.frame(in: .local).midX,
                                                 y: geometry.frame(in: .local).midY)
                                )
                        }
                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .offset(y: 200))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)),removal: .scale(scale: 0.8).combined(with: .opacity)))
                    }
                }

            }
            .onAppear {
                setupBGM()
             }
            .onDisappear {
                bgmPlayer?.stop()
            }
        }
    
    private func setupBGM() {
        guard let url = Bundle.main.url(forResource: "startSound", withExtension: ".mp3") else {
            print("BGM文件未找到")
            return
        }
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1  // 无限循环
            bgmPlayer?.volume = 0.3       // 音量设置
            bgmPlayer?.play()
        } catch {
            print("BGM播放失败: \(error.localizedDescription)")
        }
    }
}

#Preview("初始状态"){
    StartView(currentState:.constant(mainView.GameState.start))
}
#Preview("进行中状态") {
    ContentView(currentState: .constant(.playing))
}

