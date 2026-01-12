//
//  WeightRecordView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct WeightRecordView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var weightKitManager = WeightKitManager()
    
    @State private var weightText = ""
    @State private var measurementDate = Date()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var showingHistory = false
    @State private var hasManuallyEditedDate = false
    @FocusState private var isWeightFocused: Bool
    
    private var isDark: Bool { colorScheme == .dark }
    
    // 主题颜色
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
    
    private var cardBackground: Color {
        isDark ? Color(white: 0.15) : .white
    }
    
    private var primaryTextColor: Color {
        isDark ? Color(white: 0.95) : Color(white: 0.15)
    }
    
    private var secondaryTextColor: Color {
        isDark ? Color(white: 0.6) : Color(white: 0.45)
    }
    
    private var tertiaryTextColor: Color {
        isDark ? Color(white: 0.5) : Color(white: 0.35)
    }
    
    // 体重状态判断
    private var weightStatus: (text: String, color: Color) {
        guard let weight = Double(weightText) else {
            return ("请输入体重", secondaryTextColor)
        }
        
        if weight < 45 {
            return ("偏轻", .blue)
        } else if weight < 65 {
            return ("正常", .green)
        } else if weight < 80 {
            return ("偏重", .orange)
        } else {
            return ("肥胖", .red)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                .gesture(
                    DragGesture(minimumDistance: 30, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width < -30 || value.translation.height > 30 {
                                hideKeyboard()
                            }
                        }
                )
            
            VStack(spacing: 16) {
                // 顶部图标和状态
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.green.opacity(isDark ? 0.5 : 0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    
                    Text(weightStatus.text)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(weightStatus.color)
                        .animation(.easeInOut, value: weightStatus.text)
                }
                .onTapGesture {
                    hideKeyboard()
                }
                
                // 体重输入区域
                VStack(spacing: 12) {
                    // 体重输入卡片
                    HStack(spacing: 14) {
                        // 左侧图标
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(isDark ? 0.25 : 0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                        }
                        
                        // 标题
                        VStack(alignment: .leading, spacing: 2) {
                            Text("体重")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                            
                            Text("公斤")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        // 输入框
                        HStack(spacing: 4) {
                            TextField("65.0", text: $weightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                                .frame(width: 80)
                                .focused($isWeightFocused)
                            
                            Text("kg")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cardBackground)
                            .shadow(color: isWeightFocused ? Color.green.opacity(isDark ? 0.4 : 0.25) : .black.opacity(isDark ? 0.25 : 0.05), radius: isWeightFocused ? 10 : 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isWeightFocused ? Color.green.opacity(0.5) : .clear, lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isWeightFocused)
                    
                    // 快速调整按钮
                    HStack(spacing: 10) {
                        ForEach([-1.0, -0.5, 0.5, 1.0], id: \.self) { delta in
                            Button(action: {
                                adjustWeight(by: delta)
                            }) {
                                Text(delta > 0 ? "+\(String(format: "%.1f", delta))" : String(format: "%.1f", delta))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(delta > 0 ? .orange : .green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill((delta > 0 ? Color.orange : Color.green).opacity(isDark ? 0.2 : 0.12))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 日期时间选择
                HStack {
                    Text("测量时间")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(tertiaryTextColor)
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { measurementDate },
                            set: { newValue in
                                isWeightFocused = false
                                measurementDate = newValue
                                hasManuallyEditedDate = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    hideKeyboard()
                                }
                            }
                        ),
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.green)
                    .onTapGesture {
                        isWeightFocused = false
                    }
                }
                .padding(.horizontal, 20)
                .onTapGesture {
                    isWeightFocused = false
                    hideKeyboard()
                }
                
                // 保存按钮
                Button(action: saveWeight) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                        }
                        Text(isSaving ? "保存中..." : "保存到健康")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.green.opacity(isDark ? 0.6 : 0.4), radius: 10, x: 0, y: 5)
                }
                .disabled(isSaving || !isInputValid)
                .opacity(isInputValid ? 1.0 : 0.6)
                .padding(.horizontal, 20)
                
                // 趋势图
                WeightTrendView(
                    records: weightKitManager.recentRecords,
                    isDark: isDark,
                    cardBackground: cardBackground,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor
                )
                .padding(.horizontal, 20)
                .onTapGesture {
                    showingHistory = true
                }
                
                Spacer(minLength: 0)
            }
            .padding(.top, 10)
        }
        .navigationTitle("体重记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完成") {
                        hideKeyboard()
                    }
                    .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.green)
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            WeightHistoryView(weightKitManager: weightKitManager)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            await weightKitManager.requestAuthorization()
        }
    }
    
    private var isInputValid: Bool {
        guard let weight = Double(weightText) else {
            return false
        }
        return weight > 20 && weight < 300
    }
    
    private func hideKeyboard() {
        isWeightFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func adjustWeight(by delta: Double) {
        let currentWeight = Double(weightText) ?? 65.0
        let newWeight = max(20, min(300, currentWeight + delta))
        weightText = String(format: "%.1f", newWeight)
    }
    
    private func saveWeight() {
        hideKeyboard()
        
        guard let weight = Double(weightText) else {
            alertTitle = "输入错误"
            alertMessage = "请输入有效的体重值"
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try await weightKitManager.saveWeight(weight, date: measurementDate)
                
                await MainActor.run {
                    isSaving = false
                    alertTitle = "保存成功 ✓"
                    alertMessage = "体重 \(String(format: "%.1f", weight)) kg 已保存到健康应用"
                    showingAlert = true
                    
                    // 清空输入
                    weightText = ""
                    measurementDate = Date()
                    hasManuallyEditedDate = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertTitle = "保存失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WeightRecordView()
    }
}
