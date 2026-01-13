# BPRecorder 健康记录

一款简洁优雅的 iOS 健康数据记录应用，将健康数据直接保存到 Apple 健康应用。

## ✨ 功能特性

### 📋 侧边栏导航
- 便捷的侧边栏模块切换
- 支持多个健康数据模块
- 流畅的滑动动画效果

### 📝 血压记录
- 输入收缩压（高压）和舒张压（低压）
- 可选输入心率
- 自定义测量时间
- 一键保存到 Apple 健康应用

### 📊 数据可视化
- **趋势图表**：显示最近 7 天的血压变化趋势
- **历史记录**：查看所有血压记录，按日期分组
- **数据概览**：平均血压、正常/异常次数统计

### 🎨 血压状态识别
| 状态 | 收缩压 | 舒张压 | 颜色 |
|------|--------|--------|------|
| 正常 | < 120 | < 80 | 🟢 绿色 |
| 偏高 | 120-139 | 80-89 | 🟠 橙色 |
| 高血压 | ≥ 140 | ≥ 90 | 🔴 红色 |
| 偏低 | < 90 | < 60 | 🔵 蓝色 |

### ⚖️ 体重记录
- 输入体重数据（公斤）
- 快速调整按钮（±0.5kg、±1kg）
- 自定义测量时间
- 一键保存到 Apple 健康应用
- **趋势图表**：显示最近 30 天的体重变化趋势
- **历史记录**：查看所有体重记录，按日期分组
- **数据概览**：平均体重、最高/最低体重、期间变化

### 🎨 体重状态识别
| 状态 | 体重范围 | 颜色 |
|------|----------|------|
| 偏轻 | < 45 kg | 🔵 蓝色 |
| 正常 | 45-65 kg | 🟢 绿色 |
| 偏重 | 65-80 kg | 🟠 橙色 |
| 肥胖 | > 80 kg | 🔴 红色 |

### 🩸 血液检测
- 记录完整血液检测指标（47+ 项指标）
- **重点监测**：WBC、NEUT#、HGB、PLT 四项关键指标
- **两种录入方式**：
  - 手动录入：逐项填写所有指标
  - 粘贴导入：支持中文字段名 JSON 快速导入（单条或数组格式）
- 支持 EVENT 标签（治疗方案/周期/天数）自动解析
- **本地 JSON 存储**（不依赖 HealthKit，数据完全本地化）
- **趋势图表**：
  - 重点指标 2x2 趋势图（显示数据点数值）
  - 单指标详细趋势图（完整历史数据）
- **历史记录**：按日期分组、按治疗方案筛选、滑动删除
- **所有指标浏览**：按分类查看、搜索、查看单指标趋势
- **智能日期解析**：支持多种日期格式（mm.dd、yyyy-mm-dd、yy-mm-dd 等）
- **重复数据处理**：导入时自动检测重复日期，支持替换或仅新增

### 🔬 血液指标分类
| 分类 | 指标数量 | 示例 |
|------|----------|------|
| 综合指数 | 4 | NLR、PLR、LMR、PNI |
| 血常规 | 24 | WBC、RBC、HGB、PLT 等 |
| 肝肾功能 | 16 | ALT、AST、肌酐、尿素氮等 |
| 肿瘤标志物 | 3 | CEA、CA125、CA199 |

### 🌓 界面特性
- **侧边栏导航**：可折叠/展开，图标始终可见，支持滑动展开/收起
- **自动适配**：亮色/暗色主题自动切换
- **流畅动画**：所有交互都有平滑的动画效果
- **键盘管理**：支持点击空白区域、左滑、滚动等多种方式关闭键盘
- **数据可视化**：趋势图显示每个数据点的具体数值
- **滑动删除**：左滑历史记录即可删除（带确认）
- **简洁直观**：卡片式设计，信息层次清晰

## 📱 系统要求

- iOS 17.0+
- iPhone / iPad
- 需要授权访问健康数据

## 🔒 隐私说明

本应用需要以下权限：

**HealthKit 数据（血压/体重模块）：**
- **读取**：血压、心率、体重数据（用于显示历史记录和趋势）
- **写入**：血压、心率、体重数据（用于保存测量结果）

**本地存储（血液检测模块）：**
- 血液检测数据存储在应用本地 JSON 文件中
- 路径：`Application Support/BPRecorder/blood_tests.json`

所有数据不会上传到任何服务器。

## 🛠 技术栈

- **SwiftUI** - 声明式 UI 框架
- **HealthKit** - 健康数据读写（血压/体重模块）
- **JSON/Codable** - 本地数据持久化（血液检测模块）
- **Swift Concurrency** - async/await 异步编程
- **Combine** - 响应式数据流管理
- **Core Graphics** - 自定义折线图绘制
- **@FocusState** - 键盘焦点管理
- **DragGesture** - 滑动交互（侧边栏、删除）

## 📁 项目结构

```
BPRecorder/
├── BPRecorderApp.swift          # 应用入口
├── MainTabView.swift            # 侧边栏导航主视图
│
├── 血压模块/
│   ├── ContentView.swift            # 血压记录主界面
│   ├── HealthKitManager.swift       # 血压数据管理
│   ├── BloodPressureTrendView.swift # 血压趋势图
│   └── HistoryView.swift            # 血压历史记录
│
├── 体重模块/
│   ├── WeightRecordView.swift       # 体重记录主界面
│   ├── WeightKitManager.swift       # 体重数据管理
│   ├── WeightTrendView.swift        # 体重趋势图
│   └── WeightHistoryView.swift      # 体重历史记录
│
├── 血液检测模块/
│   ├── BloodTestRecordView.swift    # 血液检测主界面
│   ├── BloodTestModels.swift        # 数据模型与指标定义
│   ├── BloodTestKitManager.swift    # JSON 数据管理
│   ├── BloodTestTrendView.swift     # 重点趋势图
│   ├── BloodTestHistoryView.swift   # 历史记录
│   ├── BloodTestDetailView.swift    # 单条记录详情
│   ├── AllMetricsView.swift         # 所有指标浏览
│   └── MetricTrendDetailView.swift  # 单指标趋势详情
│
├── BPRecorder.entitlements      # HealthKit 权限配置
└── Assets.xcassets/             # 资源文件
    └── AppIcon.appiconset/      # 应用图标
```

## 🚀 快速开始

1. 使用 Xcode 打开 `BPRecorder.xcodeproj`
2. 选择目标设备（iPhone 模拟器或真机）
3. 运行项目 (⌘R)
4. 首次运行会请求健康数据访问权限，请允许

## 📄 许可证

MIT License

---

Made with ❤️ using SwiftUI

