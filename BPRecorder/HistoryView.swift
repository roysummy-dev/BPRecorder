//
//  HistoryView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/11.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthKitManager: HealthKitManager
    
    @State private var recordToDelete: BloodPressureRecord?
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
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
    
    private var cardBackground: Color {
        isDark ? Color(white: 0.15) : .white
    }
    
    private var primaryTextColor: Color {
        isDark ? Color(white: 0.95) : Color(white: 0.15)
    }
    
    private var secondaryTextColor: Color {
        isDark ? Color(white: 0.6) : Color(white: 0.45)
    }
    
    // 按日期分组的记录
    private var groupedRecords: [(String, [BloodPressureRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        
        let grouped = Dictionary(grouping: healthKitManager.allRecords) { record in
            formatter.string(from: record.date)
        }
        
        return grouped.sorted { first, second in
            guard let date1 = healthKitManager.allRecords.first(where: { formatter.string(from: $0.date) == first.key })?.date,
                  let date2 = healthKitManager.allRecords.first(where: { formatter.string(from: $0.date) == second.key })?.date else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if healthKitManager.allRecords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无血压记录")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        Text("记录的血压数据将显示在这里")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(secondaryTextColor.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                            // 趋势概览
                            Section {
                                TrendSummaryView(
                                    records: healthKitManager.allRecords,
                                    isDark: isDark,
                                    cardBackground: cardBackground,
                                    primaryTextColor: primaryTextColor,
                                    secondaryTextColor: secondaryTextColor
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // 删除提示
                            HStack {
                                Image(systemName: "hand.draw")
                                    .font(.system(size: 11))
                                Text("左滑记录可删除")
                                    .font(.system(size: 11, design: .rounded))
                            }
                            .foregroundStyle(secondaryTextColor.opacity(0.6))
                            .padding(.top, 4)
                            
                            // 历史记录列表
                            ForEach(groupedRecords, id: \.0) { dateString, records in
                                Section {
                                    ForEach(records) { record in
                                        HistoryRecordRow(
                                            record: record,
                                            isDark: isDark,
                                            cardBackground: cardBackground,
                                            primaryTextColor: primaryTextColor,
                                            secondaryTextColor: secondaryTextColor,
                                            onDelete: {
                                                recordToDelete = record
                                                showDeleteAlert = true
                                            }
                                        )
                                    }
                                } header: {
                                    HStack {
                                        Text(dateString)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(secondaryTextColor)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(backgroundColor)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                
                // 删除中遮罩
                if isDeleting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("血压历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
            .alert("删除记录", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {
                    recordToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let record = recordToDelete {
                        deleteRecord(record)
                    }
                }
            } message: {
                if let record = recordToDelete {
                    Text("确定要删除 \(Int(record.systolic))/\(Int(record.diastolic)) mmHg 的血压记录吗？此操作将同时从健康应用中删除该数据。")
                }
            }
        }
        .task {
            await healthKitManager.fetchAllRecords()
        }
    }
    
    private func deleteRecord(_ record: BloodPressureRecord) {
        isDeleting = true
        Task {
            do {
                try await healthKitManager.deleteRecord(record)
                await MainActor.run {
                    isDeleting = false
                    recordToDelete = nil
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    recordToDelete = nil
                }
            }
        }
    }
}

// MARK: - 趋势概览
struct TrendSummaryView: View {
    let records: [BloodPressureRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var avgSystolic: Double {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.systolic }.reduce(0, +) / Double(records.count)
    }
    
    private var avgDiastolic: Double {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.diastolic }.reduce(0, +) / Double(records.count)
    }
    
    private var normalCount: Int {
        records.filter { $0.status == .normal }.count
    }
    
    private var abnormalCount: Int {
        records.filter { $0.status != .normal }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.pink)
                Text("数据概览")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Spacer()
                Text("共 \(records.count) 条记录")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            
            HStack(spacing: 12) {
                // 平均血压
                StatCard(
                    title: "平均血压",
                    value: "\(Int(avgSystolic))/\(Int(avgDiastolic))",
                    unit: "mmHg",
                    color: .pink,
                    isDark: isDark
                )
                
                // 正常次数
                StatCard(
                    title: "正常",
                    value: "\(normalCount)",
                    unit: "次",
                    color: .green,
                    isDark: isDark
                )
                
                // 异常次数
                StatCard(
                    title: "异常",
                    value: "\(abnormalCount)",
                    unit: "次",
                    color: abnormalCount > 0 ? .orange : .gray,
                    isDark: isDark
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.5))
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(unit)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(isDark ? 0.15 : 0.1))
        )
    }
}

// MARK: - 历史记录行
struct HistoryRecordRow: View {
    let record: BloodPressureRecord
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    
    private var statusColor: Color {
        switch record.status {
        case .low: return .blue
        case .normal: return .green
        case .elevated: return .orange
        case .high: return .red
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: record.date)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮（底层）
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onDelete?()
                }
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 48)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.trailing, 20)
            .opacity(offset < -10 ? 1 : 0)
            
            // 主内容（顶层）
            HStack(spacing: 12) {
                // 状态指示器
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                // 时间
                Text(timeString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(secondaryTextColor)
                    .frame(width: 50, alignment: .leading)
                
                // 血压值
                HStack(spacing: 2) {
                    Text("\(Int(record.systolic))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Text("/")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(secondaryTextColor)
                    Text("\(Int(record.diastolic))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
                
                Text("mmHg")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                
                Spacer()
                
                // 状态标签
                Text(record.status.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor.opacity(isDark ? 0.2 : 0.12))
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
                    .shadow(color: .black.opacity(isDark ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -75)
                            } else if offset < 0 {
                                offset = min(0, offset + value.translation.width)
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.width < -30 || value.predictedEndTranslation.width < -40 {
                                offset = -75
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}

