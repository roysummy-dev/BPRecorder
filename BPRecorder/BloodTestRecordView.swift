//
//  BloodTestRecordView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct BloodTestRecordView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var manager = BloodTestKitManager()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingHistory = false
    @State private var showingAllMetrics = false
    @State private var showingImport = false
    @State private var showingManualInput = false
    
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部图标
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.purple.opacity(isDark ? 0.5 : 0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "drop.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    
                    Text("血液检测")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(primaryTextColor)
                }
                .padding(.top, 6)
                
                // 最新记录概览（放在最上面）
                if let latest = manager.latestRecord {
                    LatestRecordCard(
                        record: latest,
                        previousRecord: manager.records.count > 1 ? manager.records[1] : nil,
                        isDark: isDark,
                        cardBackground: cardBackground,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor
                    )
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        showingHistory = true
                    }
                }
                
                // 重点趋势图
                BloodTestTrendView(
                    records: manager.records,
                    isDark: isDark,
                    cardBackground: cardBackground,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    onTap: { showingHistory = true }
                )
                .padding(.horizontal, 20)
                
                // 查看全部指标入口
                Button(action: { showingAllMetrics = true }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.purple)
                        Text("查看全部指标趋势")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                            .shadow(color: .black.opacity(isDark ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                
                // 录入方式选择卡片（放在下面）
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.purple)
                        Text("新增记录")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                    }
                    
                    // 手动录入按钮
                    Button(action: { showingManualInput = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(isDark ? 0.2 : 0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("手动录入")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                Text("逐项填写检测指标")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(isDark ? 0.1 : 0.05))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // 粘贴导入按钮
                    Button(action: { showingImport = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(isDark ? 0.2 : 0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("粘贴导入")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                Text("从 JSON 数据批量导入")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(isDark ? 0.1 : 0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(cardBackground)
                        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 6)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("血液检测")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.purple)
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            BloodTestHistoryView(manager: manager)
        }
        .sheet(isPresented: $showingAllMetrics) {
            AllMetricsView(manager: manager, mode: .browse)
        }
        .sheet(isPresented: $showingImport) {
            ImportJSONView(manager: manager) { message in
                alertTitle = "导入成功 ✓"
                alertMessage = message
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingManualInput) {
            ManualInputView(manager: manager) { message in
                alertTitle = "保存成功 ✓"
                alertMessage = message
                showingAlert = true
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            await manager.refresh()
        }
    }
}

// MARK: - 手动录入视图
struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var manager: BloodTestKitManager
    var onComplete: (String) -> Void
    
    @State private var measurementDate = Date()
    @State private var eventText = ""
    @State private var metricValues: [LabMetricKey: String] = [:]
    @State private var isSaving = false
    @State private var selectedCategory: LabMetricCategory? = .bloodRoutine
    @State private var searchText = ""
    
    @FocusState private var focusedMetric: LabMetricKey?
    
    private var isDark: Bool { colorScheme == .dark }
    private var cardBackground: Color { isDark ? Color(white: 0.15) : .white }
    private var primaryTextColor: Color { isDark ? Color(white: 0.95) : Color(white: 0.15) }
    private var secondaryTextColor: Color { isDark ? Color(white: 0.6) : Color(white: 0.45) }
    
    // 筛选后的指标
    private var filteredMetrics: [LabMetricKey] {
        var result = LabMetricKey.allCases
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.shortName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // 已填写的指标数量
    private var filledCount: Int {
        metricValues.values.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    private var isValid: Bool {
        filledCount > 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 基础信息
                VStack(spacing: 12) {
                    HStack {
                        Label("检测日期", systemImage: "calendar")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        Spacer()
                        DatePicker("", selection: $measurementDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.purple)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("事件标签", systemImage: "tag")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        Spacer()
                        TextField("如 FOLFIRI C2 D11", text: $eventText)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(14)
                .background(cardBackground)
                
                Divider()
                
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(secondaryTextColor)
                    TextField("搜索指标", text: $searchText)
                        .font(.system(size: 14, design: .rounded))
                }
                .padding(10)
                .background(isDark ? Color(white: 0.12) : Color(white: 0.95))
                
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            isDark: isDark
                        ) { selectedCategory = nil }
                        
                        ForEach(LabMetricCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                isDark: isDark
                            ) { selectedCategory = category }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
                .background(isDark ? Color(white: 0.1) : Color(white: 0.97))
                
                // 指标列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredMetrics, id: \.self) { key in
                            MetricInputRow(
                                key: key,
                                value: binding(for: key),
                                isDark: isDark,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                isFocused: focusedMetric == key
                            )
                            .focused($focusedMetric, equals: key)
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    .background(cardBackground)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("手动录入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveRecord) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("保存 (\(filledCount))")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("完成") {
                            focusedMetric = nil
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private func binding(for key: LabMetricKey) -> Binding<String> {
        Binding(
            get: { metricValues[key] ?? "" },
            set: { metricValues[key] = $0 }
        )
    }
    
    private func saveRecord() {
        focusedMetric = nil
        isSaving = true
        
        var values: [LabMetricKey: Double] = [:]
        for (key, valueStr) in metricValues {
            let trimmed = valueStr.trimmingCharacters(in: .whitespaces)
            if let value = Double(trimmed) {
                values[key] = value
            }
        }
        
        let record = BloodTestRecord(
            date: measurementDate,
            event: eventText,
            values: values
        )
        
        Task {
            do {
                try await manager.saveRecord(record)
                await MainActor.run {
                    isSaving = false
                    onComplete("已保存 \(values.count) 项检测指标")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - 指标输入行
struct MetricInputRow: View {
    let key: LabMetricKey
    @Binding var value: String
    let isDark: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var isFocused: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 指标信息
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if key.isKeyMetric {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                    Text(key.displayName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    Text(key.briefName)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(key.chartColor)
                    
                    if !key.unit.isEmpty {
                        Text(key.unit)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(secondaryTextColor.opacity(0.7))
                    }
                    
                    Text("(\(key.normalRangeText.components(separatedBy: "\n").first ?? ""))")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(secondaryTextColor.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 输入框
            TextField("", text: $value)
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(value.isEmpty ? secondaryTextColor : key.chartColor)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFocused ? key.chartColor.opacity(0.1) : (isDark ? Color(white: 0.12) : Color(white: 0.95)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? key.chartColor.opacity(0.5) : .clear, lineWidth: 1.5)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isFocused ? key.chartColor.opacity(isDark ? 0.05 : 0.03) : .clear)
    }
}

// MARK: - 最新记录卡片
struct LatestRecordCard: View {
    let record: BloodTestRecord
    let previousRecord: BloodTestRecord?
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.purple)
                Text("最新记录")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Spacer()
                
                Text(dateFormatter.string(from: record.date))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(secondaryTextColor)
            }
            
            if !record.event.isEmpty {
                Text(record.event)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
            }
            
            // 重点指标
            HStack(spacing: 8) {
                ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                    MetricValueBadge(
                        key: key,
                        value: record.value(for: key),
                        change: calculateChange(for: key),
                        isDark: isDark
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
    
    private func calculateChange(for key: LabMetricKey) -> Double? {
        guard let current = record.value(for: key),
              let previous = previousRecord?.value(for: key) else {
            return nil
        }
        return current - previous
    }
}

// MARK: - 指标值徽章
struct MetricValueBadge: View {
    let key: LabMetricKey
    let value: Double?
    let change: Double?
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(key.briefName)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(key.chartColor)
            
            HStack(spacing: 2) {
                if let value = value {
                    Text(formatValue(value))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(key.chartColor)
                    
                    if let change = change {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(change >= 0 ? .orange : .green)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(key.chartColor.opacity(isDark ? 0.15 : 0.1))
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

// MARK: - 导入 JSON 视图
struct ImportJSONView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var manager: BloodTestKitManager
    var onComplete: (String) -> Void
    
    @State private var importText = ""
    @State private var isParsing = false
    @State private var parseResult: BloodTestKitManager.ImportResult?
    @State private var showDuplicateAlert = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private var isDark: Bool { colorScheme == .dark }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 标题
                    VStack(spacing: 6) {
                        Text("粘贴 JSON 数据")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text("支持单条记录或数组格式，中文字段名")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    // 输入框
                    TextEditor(text: $importText)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: parseResult == nil ? 200 : 120)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isDark ? Color(white: 0.15) : Color(white: 0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                
                // 解析结果预览
                if let result = parseResult {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(.purple)
                            Text("解析结果")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        
                        // 统计信息
                        HStack(spacing: 16) {
                            StatBadge(title: "解析成功", value: "\(result.totalParsed)", color: .green)
                            StatBadge(title: "新增", value: "\(result.newRecords.count)", color: .blue)
                            StatBadge(title: "重复", value: "\(result.duplicateRecords.count)", color: .orange)
                            if result.failedCount > 0 {
                                StatBadge(title: "失败", value: "\(result.failedCount)", color: .red)
                            }
                        }
                        
                        // 新增记录列表
                        if !result.newRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("新增记录：")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                ForEach(result.newRecords.prefix(5)) { record in
                                    HStack {
                                        Text(dateFormatter.string(from: record.date))
                                            .font(.system(size: 12, design: .rounded))
                                        if !record.event.isEmpty {
                                            Text(record.event)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text("\(record.presentKeys.count) 项")
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if result.newRecords.count > 5 {
                                    Text("... 还有 \(result.newRecords.count - 5) 条")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(isDark ? 0.15 : 0.1))
                            )
                        }
                        
                        // 重复记录列表
                        if !result.duplicateRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.system(size: 12))
                                    Text("日期重复（需确认是否替换）：")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.orange)
                                }
                                
                                ForEach(Array(zip(result.duplicateRecords, result.existingRecords)), id: \.0.id) { newRecord, existingRecord in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dateFormatter.string(from: newRecord.date))
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                        HStack {
                                            Text("已有: \(existingRecord.event.isEmpty ? "无标签" : existingRecord.event)")
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundStyle(.secondary)
                                            Text("→")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                            Text("新: \(newRecord.event.isEmpty ? "无标签" : newRecord.event)")
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(isDark ? 0.15 : 0.1))
                            )
                        }
                        
                        // 解析失败的详情
                        if !result.failures.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 12))
                                    Text("解析失败 (\(result.failures.count) 条)：")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.red)
                                }
                                
                                ForEach(result.failures.prefix(5)) { failure in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(failure.reason)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(.red)
                                        
                                        ForEach(failure.details, id: \.self) { detail in
                                            Text("• \(detail)")
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                
                                if result.failures.count > 5 {
                                    Text("... 还有 \(result.failures.count - 5) 条失败")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(isDark ? 0.15 : 0.1))
                            )
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDark ? Color(white: 0.12) : Color(white: 0.97))
                    )
                }
                
                // 错误信息
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                // 按钮
                HStack(spacing: 12) {
                    Button("取消") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                    
                    if parseResult == nil {
                        // 解析按钮
                        Button(action: parseJSON) {
                            if isParsing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Text("解析")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                        .disabled(importText.isEmpty || isParsing)
                    } else {
                        // 导入按钮
                        Button(action: saveRecords) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(parseResult?.hasDuplicates == true ? "导入并替换重复" : "确认导入")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(parseResult?.totalParsed ?? 0 > 0 ? Color.purple : Color.gray)
                        )
                        .foregroundStyle(.white)
                        .disabled(isSaving || (parseResult?.totalParsed ?? 0) == 0)
                        
                        // 仅导入新增（跳过重复）
                        if parseResult?.hasDuplicates == true && !(parseResult?.newRecords.isEmpty ?? true) {
                            Button(action: saveNewOnly) {
                                Text("仅新增")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green)
                            )
                            .foregroundStyle(.white)
                            .disabled(isSaving)
                        }
                    }
                }
                
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
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
            }
        }
        .presentationDetents([.large])
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func parseJSON() {
        isParsing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await manager.parseJSON(importText)
                await MainActor.run {
                    parseResult = result
                    isParsing = false
                    
                    if result.totalParsed == 0 {
                        errorMessage = "未能解析出有效数据"
                    }
                }
            } catch {
                await MainActor.run {
                    isParsing = false
                    errorMessage = "解析失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveRecords() {
        guard let result = parseResult else { return }
        isSaving = true
        
        Task {
            do {
                // 保存所有记录，替换重复的
                let allRecords = result.newRecords + result.duplicateRecords
                try await manager.saveImportedRecords(
                    allRecords,
                    replaceDuplicates: true,
                    duplicatesToReplace: result.duplicateRecords
                )
                
                await MainActor.run {
                    isSaving = false
                    let message = result.hasDuplicates 
                        ? "已导入 \(result.newRecords.count) 条新记录，替换 \(result.duplicateRecords.count) 条重复记录"
                        : "已导入 \(result.newRecords.count) 条记录"
                    onComplete(message)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveNewOnly() {
        guard let result = parseResult else { return }
        isSaving = true
        
        Task {
            do {
                // 只保存新记录，跳过重复
                try await manager.saveImportedRecords(result.newRecords)
                
                await MainActor.run {
                    isSaving = false
                    let message = "已导入 \(result.newRecords.count) 条新记录，跳过 \(result.duplicateRecords.count) 条重复记录"
                    onComplete(message)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存失败：\(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - 统计徽章
struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        BloodTestRecordView()
    }
}
