//
//  AllMetricsView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

enum AllMetricsViewMode {
    case browse      // 浏览趋势
    case edit(Binding<BloodTestRecord>)  // 编辑记录
}

struct AllMetricsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: BloodTestKitManager
    var mode: AllMetricsViewMode
    
    @State private var searchText = ""
    @State private var selectedCategory: LabMetricCategory?
    @State private var showingTrendDetail: LabMetricKey?
    
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
    
    // 按分类分组
    private var groupedMetrics: [(LabMetricCategory, [LabMetricKey])] {
        if selectedCategory != nil {
            return [(selectedCategory!, filteredMetrics)]
        }
        
        var result: [(LabMetricCategory, [LabMetricKey])] = []
        for category in LabMetricCategory.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let keys = filteredMetrics.filter { $0.category == category }
            if !keys.isEmpty {
                result.append((category, keys))
            }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(secondaryTextColor)
                    
                    TextField("搜索指标", text: $searchText)
                        .font(.system(size: 14, design: .rounded))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDark ? Color(white: 0.12) : Color(white: 0.95))
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            isDark: isDark
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(LabMetricCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                isDark: isDark
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                
                // 指标列表
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                        ForEach(groupedMetrics, id: \.0) { category, metrics in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(metrics, id: \.self) { key in
                                        MetricListRow(
                                            key: key,
                                            latestValue: manager.records.first?.value(for: key),
                                            hasHistory: manager.metricHistory(for: key).count > 0,
                                            isDark: isDark,
                                            primaryTextColor: primaryTextColor,
                                            secondaryTextColor: secondaryTextColor
                                        ) {
                                            showingTrendDetail = key
                                        }
                                        
                                        if key != metrics.last {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(cardBackground)
                                        .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                                )
                                .padding(.horizontal, 20)
                            } header: {
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)
                                    Text(category.rawValue)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(secondaryTextColor)
                                    
                                    Text("\(metrics.count) 项")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(secondaryTextColor.opacity(0.7))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(backgroundColor)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("所有指标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
            .sheet(item: $showingTrendDetail) { key in
                MetricTrendDetailView(key: key, manager: manager)
            }
        }
    }
}

// MARK: - 分类筛选芯片
struct CategoryChip: View {
    let category: LabMetricCategory?
    let isSelected: Bool
    let isDark: Bool
    var action: () -> Void
    
    private var color: Color {
        category?.color ?? .purple
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                
                Text(category?.rawValue ?? "全部")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : (isDark ? .white : .primary))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(isDark ? 0.2 : 0.1))
            )
        }
    }
}

// MARK: - 指标列表行
struct MetricListRow: View {
    let key: LabMetricKey
    let latestValue: Double?
    let hasHistory: Bool
    let isDark: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(key.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryTextColor)
                        
                        if key.isKeyMetric {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(key.shortName)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(key.chartColor)
                        
                        if !key.unit.isEmpty {
                            Text(key.unit)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(secondaryTextColor.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // 最新值
                if let value = latestValue {
                    Text(formatValue(value))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(key.chartColor)
                }
                
                // 趋势指示
                if hasHistory {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                        .foregroundStyle(secondaryTextColor)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(secondaryTextColor.opacity(0.5))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
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

