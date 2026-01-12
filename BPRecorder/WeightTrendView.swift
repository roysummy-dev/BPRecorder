//
//  WeightTrendView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

struct WeightTrendView: View {
    let records: [WeightRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var sortedRecords: [WeightRecord] {
        records.sorted { $0.date < $1.date }.suffix(10).map { $0 }
    }
    
    private var weightRange: (min: Double, max: Double) {
        guard !sortedRecords.isEmpty else { return (50, 80) }
        let allValues = sortedRecords.map { $0.weight }
        let minVal = max(30, (allValues.min() ?? 50) - 8)
        let maxVal = min(150, (allValues.max() ?? 80) + 8)
        return (minVal, maxVal)
    }
    
    private var weightChange: Double? {
        guard sortedRecords.count >= 2 else { return nil }
        return sortedRecords.last!.weight - sortedRecords.first!.weight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.green)
                Text("体重趋势")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Spacer()
                
                Text("最近30天")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(secondaryTextColor)
            }
            
            if sortedRecords.isEmpty {
                // 无数据提示
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 28))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无体重记录")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // 折线图
                GeometryReader { geometry in
                    let width = geometry.size.width - 20
                    let height = geometry.size.height - 30  // 留更多空间给标签
                    let offsetX: CGFloat = 10
                    let offsetY: CGFloat = 18  // 顶部留空间给数值标签
                    let range = weightRange
                    let valueRange = range.max - range.min
                    
                    ZStack {
                        // 体重折线
                        if sortedRecords.count > 1 {
                            // 填充区域
                            Path { path in
                                for (index, record) in sortedRecords.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1)
                                    let y = offsetY + height - ((record.weight - range.min) / valueRange * height)
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
                                    colors: [.green.opacity(0.3), .green.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            // 折线
                            Path { path in
                                for (index, record) in sortedRecords.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1)
                                    let y = offsetY + height - ((record.weight - range.min) / valueRange * height)
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                        }
                        
                        // 数据点和数值标签
                        ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
                            let x = sortedRecords.count > 1
                                ? offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1)
                                : offsetX + width / 2
                            let y = offsetY + height - ((record.weight - range.min) / valueRange * height)
                            
                            // 数据点
                            Circle()
                                .fill(statusColor(for: record))
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                            
                            // 数值标签（交错显示避免重叠）
                            let labelY = index % 2 == 0 ? y - 12 : y + 12
                            Text(String(format: "%.1f", record.weight))
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(statusColor(for: record))
                                .position(x: x, y: labelY)
                        }
                    }
                }
                .frame(height: 130)
                
                // 图例和当前体重
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("体重").font(.system(size: 10, design: .rounded)).foregroundStyle(secondaryTextColor)
                    }
                    
                    if let change = weightChange {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "%.1f kg", abs(change)))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(change >= 0 ? .orange : .green)
                    }
                    
                    Spacer()
                    
                    if let latest = sortedRecords.last {
                        Text(String(format: "%.1f kg", latest.weight))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor(for: latest))
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .shadow(color: .black.opacity(isDark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
        )
    }
    
    private func statusColor(for record: WeightRecord) -> Color {
        switch record.status {
        case .underweight: return .blue
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
        }
    }
}
