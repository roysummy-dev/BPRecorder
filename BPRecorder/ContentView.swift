//
//  ContentView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/11.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var healthKitManager = HealthKitManager()
    
    @State private var systolicText = ""
    @State private var diastolicText = ""
    @State private var heartRateText = ""
    @State private var measurementDate = Date()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var showingHistory = false
    @State private var hasManuallyEditedDate = false
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case systolic, diastolic, heartRate
    }
    
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
    
    // 血压状态判断
    private var bloodPressureStatus: (text: String, color: Color) {
        guard let systolic = Double(systolicText),
              let diastolic = Double(diastolicText) else {
            return ("请输入血压值", secondaryTextColor)
        }
        
        if systolic < 90 || diastolic < 60 {
            return ("偏低", .blue)
        } else if systolic < 120 && diastolic < 80 {
            return ("正常", .green)
        } else if systolic < 140 || diastolic < 90 {
            return ("偏高", .orange)
        } else {
            return ("高血压", .red)
        }
    }
    
    var body: some View {
        NavigationStack {
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
                                // 左滑或下滑关闭键盘
                                if value.translation.width < -30 || value.translation.height > 30 {
                                    hideKeyboard()
                                }
                            }
                    )
                
                VStack(spacing: 12) {
                    // 顶部心形图标和状态
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.red.opacity(isDark ? 0.5 : 0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating)
                        }
                        
                        Text(bloodPressureStatus.text)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(bloodPressureStatus.color)
                            .animation(.easeInOut, value: bloodPressureStatus.text)
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                    
                    // 血压输入区域
                    VStack(spacing: 10) {
                        BloodPressureInputField(
                            title: "收缩压",
                            subtitle: "高压",
                            value: $systolicText,
                            unit: "mmHg",
                            iconColor: .red,
                            placeholder: "120",
                            isDark: isDark,
                            cardBackground: cardBackground,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            isFocused: $focusedField,
                            field: .systolic
                        )
                        
                        BloodPressureInputField(
                            title: "舒张压",
                            subtitle: "低压",
                            value: $diastolicText,
                            unit: "mmHg",
                            iconColor: .blue,
                            placeholder: "80",
                            isDark: isDark,
                            cardBackground: cardBackground,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            isFocused: $focusedField,
                            field: .diastolic
                        )
                        
                        BloodPressureInputField(
                            title: "心率",
                            subtitle: "可选",
                            value: $heartRateText,
                            unit: "次/分",
                            iconColor: .pink,
                            placeholder: "72",
                            icon: "waveform.path.ecg",
                            isDark: isDark,
                            cardBackground: cardBackground,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            isFocused: $focusedField,
                            field: .heartRate
                        )
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
                                    // 先清除输入框焦点
                                    focusedField = nil
                                    measurementDate = newValue
                                    hasManuallyEditedDate = true
                                    // 选择后关闭日期选择器
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
                        .tint(.pink)
                        .onTapGesture {
                            // 点击日期选择器时先清除输入框焦点
                            focusedField = nil
                        }
                    }
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        focusedField = nil
                        hideKeyboard()
                    }
                    
                    // 保存按钮
                    Button(action: saveBloodPressure) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 16))
                            }
                            Text(isSaving ? "保存中..." : "保存到健康")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.red.opacity(isDark ? 0.6 : 0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSaving || !isInputValid)
                    .opacity(isInputValid ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    
                    // 趋势图
                    BloodPressureTrendView(
                        records: healthKitManager.recentRecords,
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
                .padding(.top, 6)
            }
            .navigationTitle("血压记录")
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
                            .foregroundStyle(.pink)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(healthKitManager: healthKitManager)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            await healthKitManager.requestAuthorization()
        }
    }
    
    private var isInputValid: Bool {
        guard let systolic = Double(systolicText),
              let diastolic = Double(diastolicText) else {
            return false
        }
        return systolic > 0 && systolic < 300 && diastolic > 0 && diastolic < 200
    }
    
    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveBloodPressure() {
        hideKeyboard()
        
        guard let systolic = Double(systolicText),
              let diastolic = Double(diastolicText) else {
            alertTitle = "输入错误"
            alertMessage = "请输入有效的血压值"
            showingAlert = true
            return
        }
        
        let heartRate = Double(heartRateText)
        
        isSaving = true
        
        Task {
            do {
                try await healthKitManager.saveBloodPressure(
                    systolic: systolic,
                    diastolic: diastolic,
                    heartRate: heartRate,
                    date: measurementDate
                )
                
                await MainActor.run {
                    isSaving = false
                    alertTitle = "保存成功 ✓"
                    alertMessage = "血压 \(Int(systolic))/\(Int(diastolic)) mmHg 已保存到健康应用"
                    showingAlert = true
                    
                    // 清空输入
                    systolicText = ""
                    diastolicText = ""
                    heartRateText = ""
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

// MARK: - 血压输入组件
struct BloodPressureInputField: View {
    let title: String
    let subtitle: String
    @Binding var value: String
    let unit: String
    let iconColor: Color
    var placeholder: String = ""
    var icon: String = "drop.fill"
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var isFocused: FocusState<ContentView.FocusedField?>.Binding
    let field: ContentView.FocusedField
    
    private var isFieldFocused: Bool {
        isFocused.wrappedValue == field
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(isDark ? 0.25 : 0.15))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }
            
            // 标题和副标题
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            
            Spacer()
            
            // 输入框
            HStack(spacing: 4) {
                TextField(placeholder, text: $value)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                    .frame(width: 65)
                    .focused(isFocused, equals: field)
                
                Text(unit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
                .shadow(color: isFieldFocused ? iconColor.opacity(isDark ? 0.4 : 0.25) : .black.opacity(isDark ? 0.25 : 0.05), radius: isFieldFocused ? 8 : 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFieldFocused ? iconColor.opacity(0.5) : .clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFieldFocused)
    }
}

#Preview {
    ContentView()
}
