//
//  BloodTestTrendView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct BloodTestTrendView: View {
    let records: [BloodTestRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    var onTap: (() -> Void)?
    
    @State private var selectedDays: Int? = 30
    
    private var filteredRecords: [BloodTestRecord] {
        var result = records.sorted { $0.date < $1.date }
        
        if let days = selectedDays {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            result = result.filter { $0.date >= cutoffDate }
        }
        
        return Array(result.suffix(10))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题栏
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.purple)
                Text("重点指标趋势")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Spacer()
                
                // 时间选择器
                Menu {
                    Button("最近7天") { selectedDays = 7 }
                    Button("最近30天") { selectedDays = 30 }
                    Button("全部") { selectedDays = nil }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedDays == nil ? "全部" : "最近\(selectedDays!)天")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(secondaryTextColor)
                }
                
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryTextColor)
                        .padding(.leading, 4)
                }
            }
            
            if filteredRecords.isEmpty {
                // 无数据提示
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "drop")
                            .font(.system(size: 28))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无血液检测记录")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // 2x2 小图表
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                        MiniTrendChart(
                            key: key,
                            records: filteredRecords,
                            isDark: isDark,
                            cardBackground: cardBackground,
                            secondaryTextColor: secondaryTextColor
                        )
                    }
                }
                
                // 图例
                HStack(spacing: 16) {
                    ForEach(LabMetricKey.keyMetrics, id: \.self) { key in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(key.chartColor)
                                .frame(width: 6, height: 6)
                            Text(key.shortName)
                                .font(.system(size: 9, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - 迷你趋势图
struct MiniTrendChart: View {
    let key: LabMetricKey
    let records: [BloodTestRecord]
    let isDark: Bool
    let cardBackground: Color
    let secondaryTextColor: Color
    
    private var dataPoints: [(date: Date, value: Double)] {
        records.compactMap { record -> (Date, Double)? in
            guard let value = record.value(for: key) else { return nil }
            return (record.date, value)
        }.sorted { $0.date < $1.date }
    }
    
    private var valueRange: (min: Double, max: Double) {
        guard !dataPoints.isEmpty else { return (0, 100) }
        let values = dataPoints.map { $0.value }
        let minVal = (values.min() ?? 0) * 0.9
        let maxVal = (values.max() ?? 100) * 1.1
        return (minVal, max(minVal + 1, maxVal))
    }
    
    private var latestValue: Double? {
        dataPoints.last?.value
    }
    
    private var change: Double? {
        guard dataPoints.count >= 2 else { return nil }
        return dataPoints.last!.value - dataPoints[dataPoints.count - 2].value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题和数值
            HStack {
                Text(key.shortName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(key.chartColor)
                
                Spacer()
                
                if let value = latestValue {
                    Text(formatValue(value))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(key.chartColor)
                    
                    if let change = change {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(change >= 0 ? .orange : .green)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                }
            }
            
            // 迷你折线图
            if dataPoints.count >= 2 {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height - 12 // 留出数值标签空间
                    let offsetY: CGFloat = 10
                    let range = valueRange
                    let rangeValue = range.max - range.min
                    
                    ZStack {
                        // 折线
                        Path { path in
                            for (index, point) in dataPoints.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                let y = offsetY + height - ((point.value - range.min) / rangeValue * height)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(key.chartColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        
                        // 数据点和数值
                        ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                            let x = width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                            let y = offsetY + height - ((point.value - range.min) / rangeValue * height)
                            
                            // 数据点
                            Circle()
                                .fill(key.chartColor)
                                .frame(width: 4, height: 4)
                                .position(x: x, y: y)
                            
                            // 数值标签（交替显示在上下以避免重叠）
                            let labelY = index % 2 == 0 ? y - 8 : y + 10
                            Text(formatValueShort(point.value))
                                .font(.system(size: 7, weight: .medium, design: .rounded))
                                .foregroundStyle(key.chartColor)
                                .position(x: x, y: labelY)
                        }
                    }
                }
                .frame(height: 45)
            } else if dataPoints.count == 1 {
                // 只有一个点时显示水平线
                Rectangle()
                    .fill(key.chartColor.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                // 无数据
                Text("无数据")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(secondaryTextColor.opacity(0.5))
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(key.chartColor.opacity(isDark ? 0.15 : 0.08))
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
    
    private func formatValueShort(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - 单指标详细趋势图
struct SingleMetricTrendChart: View {
    let key: LabMetricKey
    let records: [BloodTestRecord]
    let isDark: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var dataPoints: [(date: Date, value: Double)] {
        records.compactMap { record -> (Date, Double)? in
            guard let value = record.value(for: key) else { return nil }
            return (record.date, value)
        }.sorted { $0.date < $1.date }
    }
    
    private var valueRange: (min: Double, max: Double) {
        guard !dataPoints.isEmpty else { return (0, 100) }
        let values = dataPoints.map { $0.value }
        let minVal = max(0, (values.min() ?? 0) - (values.max() ?? 0 - (values.min() ?? 0)) * 0.15)
        let maxVal = (values.max() ?? 100) * 1.15
        return (minVal, max(minVal + 1, maxVal))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dataPoints.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无数据")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                    Spacer()
                }
                .frame(height: 150)
            } else {
                GeometryReader { geometry in
                    let width = geometry.size.width - 30
                    let height = geometry.size.height - 35
                    let offsetX: CGFloat = 15
                    let offsetY: CGFloat = 20
                    let range = valueRange
                    let rangeValue = range.max - range.min
                    
                    ZStack {
                        // 折线 + 填充
                        if dataPoints.count > 1 {
                            // 填充区域
                            Path { path in
                                for (index, point) in dataPoints.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                    let y = offsetY + height - ((point.value - range.min) / rangeValue * height)
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: offsetY + height))
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                                let lastX = offsetX + width
                                path.addLine(to: CGPoint(x: lastX, y: offsetY + height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [key.chartColor.opacity(0.3), key.chartColor.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            // 折线
                            Path { path in
                                for (index, point) in dataPoints.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                    let y = offsetY + height - ((point.value - range.min) / rangeValue * height)
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(key.chartColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }
                        
                        // 数据点和标签
                        ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                            let x = dataPoints.count > 1
                                ? offsetX + width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                : offsetX + width / 2
                            let y = offsetY + height - ((point.value - range.min) / rangeValue * height)
                            
                            // 数据点
                            Circle()
                                .fill(key.chartColor)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                            
                            // 数值标签
                            Text(formatValue(point.value))
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(key.chartColor)
                                .position(x: x, y: y - 14)
                            
                            // 日期标签（间隔显示）
                            if index % max(1, dataPoints.count / 5) == 0 || index == dataPoints.count - 1 {
                                Text(dateFormatter.string(from: point.date))
                                    .font(.system(size: 8, design: .rounded))
                                    .foregroundStyle(secondaryTextColor)
                                    .position(x: x, y: offsetY + height + 12)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
            
            // 统计信息
            if !dataPoints.isEmpty {
                HStack(spacing: 16) {
                    StatLabel(title: "最新", value: formatValue(dataPoints.last?.value ?? 0), color: key.chartColor)
                    StatLabel(title: "最高", value: formatValue(dataPoints.map { $0.value }.max() ?? 0), color: .orange)
                    StatLabel(title: "最低", value: formatValue(dataPoints.map { $0.value }.min() ?? 0), color: .blue)
                    StatLabel(title: "平均", value: formatValue(dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)), color: .gray)
                    Spacer()
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
}

// MARK: - 统计标签
struct StatLabel: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

