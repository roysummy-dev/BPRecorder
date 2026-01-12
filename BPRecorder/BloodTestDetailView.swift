//
//  BloodTestDetailView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct BloodTestDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let record: BloodTestRecord
    @ObservedObject var manager: BloodTestKitManager
    
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }
    
    // 按分类分组的指标
    private var groupedMetrics: [(LabMetricCategory, [LabMetricKey])] {
        let presentKeys = record.presentKeys
        var result: [(LabMetricCategory, [LabMetricKey])] = []
        
        for category in LabMetricCategory.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let keysInCategory = presentKeys.filter { $0.category == category }
            if !keysInCategory.isEmpty {
                result.append((category, keysInCategory))
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 头部信息
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateFormatter.string(from: record.date))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                
                                if !record.event.isEmpty {
                                    Text(record.event)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(secondaryTextColor)
                                }
                            }
                            
                            Spacer()
                            
                            // 事件标签
                            if record.tags.scheme != nil || record.tags.cycle != nil || record.tags.day != nil {
                                VStack(alignment: .trailing, spacing: 4) {
                                    if let scheme = record.tags.scheme {
                                        TagBadge(text: scheme, color: .purple)
                                    }
                                    HStack(spacing: 4) {
                                        if let cycle = record.tags.cycle {
                                            TagBadge(text: "C\(cycle)", color: .blue)
                                        }
                                        if let day = record.tags.day {
                                            TagBadge(text: "D\(day)", color: .green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cardBackground)
                            .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 20)
                    
                    // 重点指标卡片
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("重点指标")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                                KeyMetricCard(
                                    key: key,
                                    value: record.value(for: key),
                                    isDark: isDark,
                                    cardBackground: cardBackground,
                                    secondaryTextColor: secondaryTextColor
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cardBackground)
                            .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 20)
                    
                    // 全部指标（按分类）
                    ForEach(groupedMetrics, id: \.0) { category, keys in
                        VStack(spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                Text(category.rawValue)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                
                                Text("\(keys.count) 项")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 0) {
                                ForEach(keys, id: \.self) { key in
                                    MetricDetailRow(
                                        key: key,
                                        value: record.value(for: key),
                                        isDark: isDark,
                                        primaryTextColor: primaryTextColor,
                                        secondaryTextColor: secondaryTextColor
                                    )
                                    
                                    if key != keys.last {
                                        Divider()
                                            .padding(.horizontal, 12)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(category.color.opacity(isDark ? 0.1 : 0.05))
                            )
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(cardBackground)
                                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // 备注
                    if let notes = record.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.orange)
                                Text("备注")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                Spacer()
                            }
                            
                            Text(notes)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(cardBackground)
                                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("检测详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
        }
    }
}

// MARK: - 标签徽章
struct TagBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - 重点指标卡片
struct KeyMetricCard: View {
    let key: LabMetricKey
    let value: Double?
    let isDark: Bool
    let cardBackground: Color
    let secondaryTextColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(key.chartColor)
                    .frame(width: 8, height: 8)
                Text(key.shortName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(key.chartColor)
                Spacer()
            }
            
            HStack {
                if let value = value {
                    Text(formatValue(value))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(key.chartColor)
                } else {
                    Text("--")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                }
                
                Spacer()
                
                Text(key.unit)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            
            // 正常范围
            Text("参考: \(key.normalRangeText.components(separatedBy: "\n").first ?? "")")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(secondaryTextColor.opacity(0.7))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(key.chartColor.opacity(isDark ? 0.12 : 0.08))
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

// MARK: - 指标详情行
struct MetricDetailRow: View {
    let key: LabMetricKey
    let value: Double?
    let isDark: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(key.displayName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Text("参考: \(key.normalRangeText.components(separatedBy: "\n").first ?? "")")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(secondaryTextColor.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if let value = value {
                    Text(formatValue(value))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(key.chartColor)
                } else {
                    Text("--")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                }
                
                if !key.unit.isEmpty {
                    Text(key.unit)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

