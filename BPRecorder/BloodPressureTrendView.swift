//
//  BloodPressureTrendView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/11.
//

import SwiftUI

struct BloodPressureTrendView: View {
    let records: [BloodPressureRecord]
    let isDark: Bool
    let cardBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
    private var sortedRecords: [BloodPressureRecord] {
        records.sorted { $0.date < $1.date }.suffix(10).map { $0 }
    }
    
    private var systolicRange: (min: Double, max: Double) {
        guard !sortedRecords.isEmpty else { return (60, 160) }
        let allValues = sortedRecords.flatMap { [$0.systolic, $0.diastolic] }
        let minVal = max(40, (allValues.min() ?? 60) - 15)
        let maxVal = min(220, (allValues.max() ?? 160) + 15)
        return (minVal, maxVal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.pink)
                Text("血压趋势")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                
                Spacer()
                
                Text("最近7天")
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
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 28))
                            .foregroundStyle(secondaryTextColor.opacity(0.5))
                        Text("暂无血压记录")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                // 折线图
                GeometryReader { geometry in
                    let width = geometry.size.width - 16  // 左右各留 8pt
                    let height = geometry.size.height - 16 // 上下各留 8pt
                    let offsetX: CGFloat = 8
                    let offsetY: CGFloat = 8
                    let range = systolicRange
                    let valueRange = range.max - range.min
                    
                    ZStack {
                        // 参考线
                        ForEach([90, 120, 140], id: \.self) { value in
                            if CGFloat(value) >= range.min && CGFloat(value) <= range.max {
                                let y = offsetY + height - ((CGFloat(value) - range.min) / valueRange * height)
                                Path { path in
                                    path.move(to: CGPoint(x: offsetX, y: y))
                                    path.addLine(to: CGPoint(x: offsetX + width, y: y))
                                }
                                .stroke(
                                    value == 120 ? Color.green.opacity(0.4) :
                                    value == 140 ? Color.red.opacity(0.4) :
                                    Color.blue.opacity(0.4),
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                                )
                            }
                        }
                        
                        // 收缩压折线
                        if sortedRecords.count > 1 {
                            Path { path in
                                for (index, record) in sortedRecords.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1)
                                    let y = offsetY + height - ((record.systolic - range.min) / valueRange * height)
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                        }
                        
                        // 舒张压折线
                        if sortedRecords.count > 1 {
                            Path { path in
                                for (index, record) in sortedRecords.enumerated() {
                                    let x = offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1)
                                    let y = offsetY + height - ((record.diastolic - range.min) / valueRange * height)
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                        }
                        
                        // 数据点
                        ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
                            let x = sortedRecords.count > 1 
                                ? offsetX + width * CGFloat(index) / CGFloat(sortedRecords.count - 1) 
                                : offsetX + width / 2
                            let systolicY = offsetY + height - ((record.systolic - range.min) / valueRange * height)
                            let diastolicY = offsetY + height - ((record.diastolic - range.min) / valueRange * height)
                            
                            // 收缩压点
                            Circle()
                                .fill(statusColor(for: record))
                                .frame(width: 7, height: 7)
                                .position(x: x, y: systolicY)
                            
                            // 舒张压点
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 5, height: 5)
                                .position(x: x, y: diastolicY)
                        }
                    }
                }
                .frame(height: 70)
                
                // 图例
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text("收缩压").font(.system(size: 10, design: .rounded)).foregroundStyle(secondaryTextColor)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                        Text("舒张压").font(.system(size: 10, design: .rounded)).foregroundStyle(secondaryTextColor)
                    }
                    Spacer()
                    if let latest = sortedRecords.last {
                        Text("\(Int(latest.systolic))/\(Int(latest.diastolic))")
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
    
    private func statusColor(for record: BloodPressureRecord) -> Color {
        switch record.status {
        case .low: return .blue
        case .normal: return .green
        case .elevated: return .orange
        case .high: return .red
        }
    }
}


