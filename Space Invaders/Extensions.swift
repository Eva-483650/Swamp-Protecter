//
//  Extensions.swift
//  Space Invaders
//
//  Created by A on 2025/2/19.
//

import Foundation
import SwiftUI

extension Text{
    func lilacTitle() -> some View{
        self.font(.system(size: 48,weight:.semibold))
            .fontWeight(.heavy)
            .foregroundColor(.accentColor)
        
    }
}
