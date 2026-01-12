//
//  WeightHistoryView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct WeightHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var weightKitManager: WeightKitManager
    
    @State private var recordToDelete: WeightRecord?
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
    private var groupedRecords: [(String, [WeightRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        
        let grouped = Dictionary(grouping: weightKitManager.allRecords) { record in
            formatter.string(from: record.date)
        }
        
        return grouped.sorted { first, second in
            guard let date1 = weightKitManager.allRecords.first(where: { formatter.string(from: $0.date) == first.key })?.date,
                  let date2 = weightKitManager.allRecords.first(where: { formatter.string(from: $0.date) == second.key })?.date else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if weightKitManager.allRecords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 60))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无体重记录")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        Text("记录的体重数据将显示在这里")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(secondaryTextColor.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                            // 趋势概览
                            Section {
                                WeightSummaryView(
                                    records: weightKitManager.allRecords,
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
                                        WeightRecordRow(
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
            .navigationTitle("体重历史")
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
                    Text("确定要删除 \(String(format: "%.1f", record.weight)) kg 的体重记录吗？此操作将同时从健康应用中删除该数据。")
                }
            }
        }
        .task {
            await weightKitManager.fetchAllRecords()
        }
    }
    
    private func deleteRecord(_ record: WeightRecord) {
        isDeleting = true
        Task {
            do {
                try await weightKitManager.deleteRecord(record)
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

// MARK: - 体重概览
struct WeightSummaryView: View {
    let records: [WeightRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var avgWeight: Double {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.weight }.reduce(0, +) / Double(records.count)
    }
    
    private var maxWeight: Double {
        records.map { $0.weight }.max() ?? 0
    }
    
    private var minWeight: Double {
        records.map { $0.weight }.min() ?? 0
    }
    
    private var weightChange: Double? {
        let sorted = records.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted.last!.weight - sorted.first!.weight
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green)
                Text("数据概览")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Spacer()
                Text("共 \(records.count) 条记录")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            
            HStack(spacing: 12) {
                // 平均体重
                StatCard(
                    title: "平均体重",
                    value: String(format: "%.1f", avgWeight),
                    unit: "kg",
                    color: .green,
                    isDark: isDark
                )
                
                // 最高
                StatCard(
                    title: "最高",
                    value: String(format: "%.1f", maxWeight),
                    unit: "kg",
                    color: .orange,
                    isDark: isDark
                )
                
                // 最低
                StatCard(
                    title: "最低",
                    value: String(format: "%.1f", minWeight),
                    unit: "kg",
                    color: .blue,
                    isDark: isDark
                )
            }
            
            // 变化趋势
            if let change = weightChange {
                HStack {
                    Image(systemName: change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .foregroundStyle(change >= 0 ? .orange : .green)
                    Text("期间变化")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                    Spacer()
                    Text(String(format: "%@%.1f kg", change >= 0 ? "+" : "", change))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(change >= 0 ? .orange : .green)
                }
                .padding(.top, 4)
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

// MARK: - 体重记录行
struct WeightRecordRow: View {
    let record: WeightRecord
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    
    private var statusColor: Color {
        switch record.status {
        case .underweight: return .blue
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
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
                
                // 体重值
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", record.weight))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Text("kg")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                }
                
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

