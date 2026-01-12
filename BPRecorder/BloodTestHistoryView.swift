//
//  BloodTestHistoryView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct BloodTestHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: BloodTestKitManager
    
    @State private var recordToDelete: BloodTestRecord?
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var selectedScheme: String? = nil
    @State private var showingDetail: BloodTestRecord?
    
    private var isDark: Bool { colorScheme == .dark }
    
    private var backgroundColor: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.08, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.88, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cardBackground: Color { isDark ? Color(white: 0.15) : .white }
    private var primaryTextColor: Color { isDark ? Color(white: 0.95) : Color(white: 0.15) }
    private var secondaryTextColor: Color { isDark ? Color(white: 0.6) : Color(white: 0.45) }
    
    // 筛选后的记录
    private var filteredRecords: [BloodTestRecord] {
        if let scheme = selectedScheme {
            return manager.records(byScheme: scheme)
        }
        return manager.records
    }
    
    // 按日期分组
    private var groupedRecords: [(String, [BloodTestRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        
        let grouped = Dictionary(grouping: filteredRecords) { record in
            formatter.string(from: record.date)
        }
        
        return grouped.sorted { first, second in
            guard let date1 = filteredRecords.first(where: { formatter.string(from: $0.date) == first.key })?.date,
                  let date2 = filteredRecords.first(where: { formatter.string(from: $0.date) == second.key })?.date else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if manager.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "drop")
                            .font(.system(size: 60))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无血液检测记录")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        Text("记录的检测数据将显示在这里")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(secondaryTextColor.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                            // 方案筛选
                            if !manager.allSchemes.isEmpty {
                                Section {
                                    SchemeFilterView(
                                        schemes: manager.allSchemes,
                                        selectedScheme: $selectedScheme,
                                        isDark: isDark
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // 统计概览
                            Section {
                                BloodTestSummaryView(
                                    records: filteredRecords,
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
                                        BloodTestRecordRow(
                                            record: record,
                                            isDark: isDark,
                                            cardBackground: cardBackground,
                                            primaryTextColor: primaryTextColor,
                                            secondaryTextColor: secondaryTextColor,
                                            onTap: {
                                                showingDetail = record
                                            },
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
            .navigationTitle("检测历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
            .sheet(item: $showingDetail) { record in
                BloodTestDetailView(record: record, manager: manager)
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
                    Text("确定要删除 \(record.date.formatted(date: .abbreviated, time: .omitted)) 的检测记录吗？")
                }
            }
        }
        .task {
            await manager.refresh()
        }
    }
    
    private func deleteRecord(_ record: BloodTestRecord) {
        isDeleting = true
        Task {
            do {
                try await manager.deleteRecord(id: record.id)
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

// MARK: - 方案筛选视图
struct SchemeFilterView: View {
    let schemes: [String]
    @Binding var selectedScheme: String?
    let isDark: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedScheme == nil,
                    isDark: isDark
                ) {
                    selectedScheme = nil
                }
                
                ForEach(schemes, id: \.self) { scheme in
                    FilterChip(
                        title: scheme,
                        isSelected: selectedScheme == scheme,
                        isDark: isDark
                    ) {
                        selectedScheme = scheme
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let isDark: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : (isDark ? .white : .primary))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.purple : Color.purple.opacity(isDark ? 0.2 : 0.1))
                )
        }
    }
}

// MARK: - 血液检测概览
struct BloodTestSummaryView: View {
    let records: [BloodTestRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private func averageValue(for key: LabMetricKey) -> Double? {
        let values = records.compactMap { $0.value(for: key) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                Text("数据概览")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Spacer()
                Text("共 \(records.count) 条记录")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            
            // 重点指标平均值
            HStack(spacing: 8) {
                ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                    VStack(spacing: 4) {
                        Text(key.briefName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        
                        if let avg = averageValue(for: key) {
                            Text(formatValue(avg))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(key.chartColor)
                        } else {
                            Text("--")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                        
                        Text("平均")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(secondaryTextColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(key.chartColor.opacity(isDark ? 0.15 : 0.1))
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - 记录行
struct BloodTestRecordRow: View {
    let record: BloodTestRecord
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
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
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.trailing, 20)
            .opacity(offset < -10 ? 1 : 0)
            
            // 主内容（顶层）
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // 事件标签
                    if !record.event.isEmpty {
                        Text(record.event)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                            .lineLimit(1)
                    } else {
                        Text("血液检测")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                    }
                    
                    Spacer()
                    
                    // 指标数量
                    Text("\(record.presentKeys.count) 项指标")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryTextColor)
                }
                
                // 重点指标
                HStack(spacing: 12) {
                    ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(key.chartColor)
                                .frame(width: 6, height: 6)
                            
                            if let value = record.value(for: key) {
                                Text("\(key.briefName): \(formatValue(value))")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                            } else {
                                Text("\(key.briefName): --")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor.opacity(0.5))
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
                    .shadow(color: .black.opacity(isDark ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .offset(x: offset)
            .onTapGesture {
                onTap?()
            }
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
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

