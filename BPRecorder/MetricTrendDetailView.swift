//
//  MetricTrendDetailView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct MetricTrendDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let key: LabMetricKey
    @ObservedObject var manager: BloodTestKitManager
    
    @State private var selectedDays: Int? = 30
    
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
    
    private var history: [(date: Date, value: Double)] {
        manager.metricHistory(for: key, days: selectedDays)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 指标信息卡片
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(key.chartColor)
                                .frame(width: 12, height: 12)
                            
                            Text(key.displayName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                            
                            if key.isKeyMetric {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.yellow)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("简称")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                                Text(key.briefName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(key.chartColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("单位")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                                Text(key.unit.isEmpty ? "-" : key.unit)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("分类")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                                Text(key.category.rawValue)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(key.category.color)
                            }
                        }
                        
                        Divider()
                        
                        // 正常范围
                        VStack(alignment: .leading, spacing: 4) {
                            Text("参考范围")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                            
                            Text(key.normalRangeText)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cardBackground)
                            .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 20)
                    
                    // 时间选择器
                    HStack {
                        Text("时间范围")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedDays) {
                            Text("7天").tag(Optional(7))
                            Text("30天").tag(Optional(30))
                            Text("90天").tag(Optional(90))
                            Text("全部").tag(nil as Int?)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal, 20)
                    
                    // 趋势图
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundStyle(key.chartColor)
                            Text("趋势图")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryTextColor)
                            Spacer()
                            Text("\(history.count) 条数据")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                        
                        if history.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundStyle(secondaryTextColor.opacity(0.5))
                                Text("暂无数据")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                            }
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                        } else {
                            // 详细趋势图
                            SingleMetricTrendChart(
                                key: key,
                                records: manager.records.filter { record in
                                    if let days = selectedDays {
                                        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                                        return record.date >= cutoff
                                    }
                                    return true
                                },
                                isDark: isDark,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cardBackground)
                            .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 20)
                    
                    // 历史记录列表
                    if !history.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(key.chartColor)
                                Text("历史记录")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                Spacer()
                            }
                            
                            VStack(spacing: 0) {
                                ForEach(Array(history.reversed().enumerated()), id: \.offset) { index, item in
                                    HStack {
                                        Text(dateFormatter.string(from: item.date))
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(secondaryTextColor)
                                        
                                        Spacer()
                                        
                                        Text(formatValue(item.value))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(key.chartColor)
                                        
                                        if !key.unit.isEmpty {
                                            Text(key.unit)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(secondaryTextColor)
                                        }
                                        
                                        // 变化指示
                                        if index < history.count - 1 {
                                            let prevValue = history.reversed()[index + 1].value
                                            let change = item.value - prevValue
                                            
                                            HStack(spacing: 2) {
                                                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text(formatChange(change))
                                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                            }
                                            .foregroundStyle(change >= 0 ? .orange : .green)
                                            .frame(width: 50, alignment: .trailing)
                                        } else {
                                            Color.clear.frame(width: 50)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    
                                    if index < history.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(key.chartColor.opacity(isDark ? 0.1 : 0.05))
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
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle(key.briefName)
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
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func formatChange(_ value: Double) -> String {
        let absValue = abs(value)
        if absValue >= 100 {
            return String(format: "%.0f", absValue)
        } else if absValue >= 10 {
            return String(format: "%.1f", absValue)
        } else {
            return String(format: "%.2f", absValue)
        }
    }
}

