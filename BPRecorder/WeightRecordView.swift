//
//  WeightRecordView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct WeightRecordView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    private var backgroundColor: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.92, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var secondaryTextColor: Color {
        isDark ? Color(white: 0.5) : Color(white: 0.45)
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.green.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                
                Text("体重记录")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(isDark ? .white : Color(white: 0.15))
                
                Text("功能开发中...")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
        }
        .navigationTitle("体重记录")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WeightRecordView()
    }
}

