//
//  MainTabView.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import SwiftUI

enum HealthModule: String, CaseIterable, Identifiable {
    case bloodPressure = "血压记录"
    case weight = "体重记录"
    case bloodTest = "血液检测"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .bloodTest: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bloodPressure: return .red
        case .weight: return .green
        case .bloodTest: return .purple
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedModule: HealthModule = .bloodPressure
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    
    private var isDark: Bool { colorScheme == .dark }
    
    private var sidebarBg: Color {
        isDark ? Color(red: 0.1, green: 0.1, blue: 0.14) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    
    // 折叠时的宽度
    private let collapsedWidth: CGFloat = 70
    // 展开时的宽度
    private let expandedWidth: CGFloat = 240
    // 手势触发阈值
    private let swipeThreshold: CGFloat = 50
    
    // 侧边栏手势
    private var sidebarDragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let translation = value.translation.width
                if isExpanded {
                    // 展开状态：只允许左滑（负值）
                    dragOffset = min(0, translation)
                } else {
                    // 折叠状态：只允许右滑（正值）
                    dragOffset = max(0, min(expandedWidth - collapsedWidth, translation))
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        // 展开状态：左滑超过阈值则收起
                        if translation < -swipeThreshold {
                            isExpanded = false
                        }
                    } else {
                        // 折叠状态：右滑超过阈值则展开
                        if translation > swipeThreshold {
                            isExpanded = true
                        }
                    }
                    dragOffset = 0
                }
            }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 主内容区域
            HStack(spacing: 0) {
                // 左侧占位区域（折叠的侧边栏宽度）
                Color.clear
                    .frame(width: collapsedWidth)
                
                // 分隔线
                Rectangle()
                    .fill(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                    .frame(width: 1)
                
                // 主内容
                NavigationStack {
                    Group {
                        switch selectedModule {
                        case .bloodPressure:
                            ContentView()
                        case .weight:
                            WeightRecordView()
                        case .bloodTest:
                            BloodTestRecordView()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 展开时的遮罩
            if isExpanded || isDragging {
                let progress = isExpanded ? 1.0 : dragOffset / (expandedWidth - collapsedWidth)
                Color.black.opacity(0.3 * progress)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
                    .gesture(sidebarDragGesture)
            }
            
            // 侧边栏
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    // 展开/折叠按钮
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: isExpanded ? "chevron.left" : "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isDark ? .white : .primary)
                            }
                            
                            if showExpandedContent {
                                Text("健康记录")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(isDark ? .white : Color(white: 0.15))
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal, showExpandedContent ? 16 : 12)
                        .opacity(0.5)
                    
                    // 模块列表
                    VStack(spacing: 8) {
                        ForEach(HealthModule.allCases) { module in
                            SidebarModuleButton(
                                module: module,
                                isSelected: selectedModule == module,
                                isExpanded: showExpandedContent,
                                isDark: isDark
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedModule = module
                                }
                                // 选择后自动折叠
                                if isExpanded {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isExpanded = false
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, showExpandedContent ? 12 : 15)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // 底部版本信息（仅展开时显示）
                    if showExpandedContent {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                            Text("版本 1.0")
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(isDark ? Color(white: 0.5) : Color(white: 0.5))
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: currentSidebarWidth)
                .background(sidebarBg)
                .shadow(color: .black.opacity(isExpanded ? 0.15 : 0.08), radius: isExpanded ? 15 : 8, x: 2, y: 0)
                .gesture(sidebarDragGesture)
                
                Spacer()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // 计算当前侧边栏宽度
    private var currentSidebarWidth: CGFloat {
        let baseWidth = isExpanded ? expandedWidth : collapsedWidth
        if isExpanded {
            // 展开状态：左滑时减少宽度
            return max(collapsedWidth, baseWidth + dragOffset)
        } else {
            // 折叠状态：右滑时增加宽度
            return min(expandedWidth, baseWidth + dragOffset)
        }
    }
    
    // 是否显示展开内容（当宽度超过阈值时显示）
    private var showExpandedContent: Bool {
        currentSidebarWidth > (collapsedWidth + expandedWidth) / 2
    }
}

// MARK: - 侧边栏模块按钮
struct SidebarModuleButton: View {
    let module: HealthModule
    let isSelected: Bool
    let isExpanded: Bool
    let isDark: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isSelected ? module.color : module.color.opacity(isDark ? 0.2 : 0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : module.color)
                }
                
                if isExpanded {
                    Text(module.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(isDark ? .white : Color(white: 0.2))
                    
                    Spacer()
                    
                    // 选中指示器
                    if isSelected {
                        Circle()
                            .fill(module.color)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, isExpanded ? 12 : 0)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: isExpanded ? .leading : .center)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected && isExpanded ? module.color.opacity(isDark ? 0.15 : 0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
