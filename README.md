# BPRecorder 血压记录

一款简洁优雅的 iOS 血压记录应用，将血压数据直接保存到 Apple 健康应用。

## ✨ 功能特性

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

### 🌓 界面特性
- 自动适配亮色/暗色主题
- 流畅的动画效果
- 简洁直观的操作体验
- 左滑删除历史记录

## 📱 系统要求

- iOS 17.0+
- iPhone / iPad
- 需要授权访问健康数据

## 🔒 隐私说明

本应用需要以下健康数据权限：
- **读取**：血压、心率数据（用于显示历史记录）
- **写入**：血压、心率数据（用于保存测量结果）

所有数据均存储在 Apple 健康应用中，不会上传到任何服务器。

## 🛠 技术栈

- **SwiftUI** - 声明式 UI 框架
- **HealthKit** - 健康数据读写
- **Swift Concurrency** - async/await 异步编程

## 📁 项目结构

```
BPRecorder/
├── BPRecorderApp.swift          # 应用入口
├── ContentView.swift            # 主界面（血压输入）
├── HealthKitManager.swift       # 健康数据管理
├── BloodPressureTrendView.swift # 血压趋势图
├── HistoryView.swift            # 历史记录页面
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

