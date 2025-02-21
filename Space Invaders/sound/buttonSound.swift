//
//  buttonSound.swift
//  Space Invaders
//
//  Created by A on 2025/2/21.
//

import SwiftUI
import AVKit

class SoundManager{
    
    static let instance = SoundManager()
    
    var player:AVAudioPlayer?
    
    enum SoundOption: String {
        case bubbleSound
        case playSound
        case startSound
    }
    
    func playSound(sound: SoundOption){
        
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ".mp3") else{ return }
        
        do{
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch let error {
            print("Error playing sound.\(error.localizedDescription)")
        }
        
    }
}

struct buttonSound: View {
    
    
    var body: some View {
        VStack(spacing: 40){
            Button("Play Sound 1") {
                SoundManager.instance.playSound(sound: .bubbleSound)
            }
            
            Button("Play Sound 2") {
                SoundManager.instance.playSound(sound: .playSound)
            }
            
            Button("Play Sound 3") {
                SoundManager.instance.playSound(sound: .startSound)
            }
        }
    }
}

#Preview {
    buttonSound()
}
