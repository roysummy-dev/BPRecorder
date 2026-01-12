//
//  BloodTestKitManager.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import Foundation
import SwiftUI

enum BloodTestError: LocalizedError {
    case fileNotFound
    case encodingFailed
    case decodingFailed
    case writeFailed
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "数据文件未找到"
        case .encodingFailed: return "数据编码失败"
        case .decodingFailed: return "数据解码失败"
        case .writeFailed: return "数据写入失败"
        case .recordNotFound: return "记录未找到"
        }
    }
}

@MainActor
class BloodTestKitManager: ObservableObject {
    @Published var records: [BloodTestRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let fileName = "blood_tests.json"
    
    init() {
        Task {
            await loadRecordsFromDisk()
        }
    }
    
    // MARK: - 文件路径
    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("BPRecorder", isDirectory: true)
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        return appFolder.appendingPathComponent(fileName)
    }
    
    // MARK: - 加载记录
    func loadRecords() async throws -> [BloodTestRecord] {
        let url = fileURL
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let records = try decoder.decode([BloodTestRecord].self, from: data)
        
        // 按日期降序排序
        return records.sorted { $0.date > $1.date }
    }
    
    private func loadRecordsFromDisk() async {
        isLoading = true
        do {
            records = try await loadRecords()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - 保存记录
    func saveRecord(_ record: BloodTestRecord) async throws {
        var allRecords = try await loadRecords()
        
        // 检查是否已存在（更新）
        if let index = allRecords.firstIndex(where: { $0.id == record.id }) {
            allRecords[index] = record
        } else {
            allRecords.append(record)
        }
        
        try await writeRecords(allRecords)
        
        // 更新本地状态
        records = allRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - 更新记录
    func updateRecord(_ record: BloodTestRecord) async throws {
        var allRecords = try await loadRecords()
        
        guard let index = allRecords.firstIndex(where: { $0.id == record.id }) else {
            throw BloodTestError.recordNotFound
        }
        
        allRecords[index] = record
        try await writeRecords(allRecords)
        
        records = allRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - 删除记录
    func deleteRecord(id: UUID) async throws {
        var allRecords = try await loadRecords()
        
        allRecords.removeAll { $0.id == id }
        try await writeRecords(allRecords)
        
        records = allRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - 按天数筛选记录
    func records(in days: Int?) async throws -> [BloodTestRecord] {
        let allRecords = try await loadRecords()
        
        guard let days = days else {
            return allRecords
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allRecords.filter { $0.date >= cutoffDate }
    }
    
    // MARK: - 按方案筛选
    func records(byScheme scheme: String) -> [BloodTestRecord] {
        records.filter { $0.tags.scheme?.lowercased() == scheme.lowercased() }
    }
    
    // MARK: - 获取所有方案
    var allSchemes: [String] {
        let schemes = records.compactMap { $0.tags.scheme }
        return Array(Set(schemes)).sorted()
    }
    
    // MARK: - 获取最近的记录
    var latestRecord: BloodTestRecord? {
        records.first
    }
    
    // MARK: - 获取指定指标的历史数据
    func metricHistory(for key: LabMetricKey, days: Int? = nil) -> [(date: Date, value: Double)] {
        var filtered = records
        
        if let days = days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            filtered = records.filter { $0.date >= cutoffDate }
        }
        
        return filtered
            .compactMap { record -> (date: Date, value: Double)? in
                guard let value = record.value(for: key) else { return nil }
                return (record.date, value)
            }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - 计算指标变化
    func metricChange(for key: LabMetricKey) -> Double? {
        guard records.count >= 2 else { return nil }
        
        let latest = records[0]
        let previous = records[1]
        
        guard let latestValue = latest.value(for: key),
              let previousValue = previous.value(for: key) else {
            return nil
        }
        
        return latestValue - previousValue
    }
    
    // MARK: - 私有写入方法
    private func writeRecords(_ records: [BloodTestRecord]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data: Data
        do {
            data = try encoder.encode(records)
        } catch {
            throw BloodTestError.encodingFailed
        }
        
        // 原子写入：先写临时文件，再替换
        let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent("blood_tests_temp.json")
        
        do {
            try data.write(to: tempURL, options: .atomic)
            
            // 如果目标文件存在，先删除
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            // 移动临时文件到目标位置
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        } catch {
            // 清理临时文件
            try? FileManager.default.removeItem(at: tempURL)
            throw BloodTestError.writeFailed
        }
    }
    
    // MARK: - 解析失败信息
    struct ParseFailure: Identifiable {
        var id = UUID()
        var index: Int              // 在数组中的索引（从1开始）
        var reason: String          // 失败原因
        var details: [String]       // 详细信息
    }
    
    // MARK: - 导入结果
    struct ImportResult {
        var newRecords: [BloodTestRecord]           // 新记录（无重复）
        var duplicateRecords: [BloodTestRecord]     // 有重复日期的记录
        var existingRecords: [BloodTestRecord]      // 已存在的记录（与 duplicateRecords 对应）
        var failures: [ParseFailure]                // 解析失败的详情
        
        var totalParsed: Int { newRecords.count + duplicateRecords.count }
        var hasDuplicates: Bool { !duplicateRecords.isEmpty }
        var failedCount: Int { failures.count }
    }
    
    // MARK: - 解析 JSON（不保存，返回解析结果）
    func parseJSON(_ jsonString: String) async throws -> ImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw BloodTestError.decodingFailed
        }
        
        var parsedRecords: [BloodTestRecord] = []
        var failures: [ParseFailure] = []
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            // 尝试解析为数组
            if let array = jsonObject as? [[String: String]] {
                for (index, dict) in array.enumerated() {
                    let parseInfo = BloodTestRecord.parseWithInfo(from: dict)
                    if !parseInfo.record.values.isEmpty {
                        parsedRecords.append(parseInfo.record)
                    } else {
                        var details: [String] = []
                        if !parseInfo.unrecognizedKeys.isEmpty {
                            details.append("无法识别的字段: \(parseInfo.unrecognizedKeys.joined(separator: ", "))")
                        }
                        if !parseInfo.invalidValues.isEmpty {
                            details.append("无效数值: \(parseInfo.invalidValues.joined(separator: ", "))")
                        }
                        if parseInfo.record.values.isEmpty && parseInfo.unrecognizedKeys.isEmpty {
                            details.append("未找到任何有效的检测指标")
                        }
                        
                        failures.append(ParseFailure(
                            index: index + 1,
                            reason: "第 \(index + 1) 条记录解析失败",
                            details: details
                        ))
                    }
                }
            }
            // 尝试解析为单个字典
            else if let dict = jsonObject as? [String: String] {
                let parseInfo = BloodTestRecord.parseWithInfo(from: dict)
                if !parseInfo.record.values.isEmpty {
                    parsedRecords.append(parseInfo.record)
                } else {
                    var details: [String] = []
                    if !parseInfo.unrecognizedKeys.isEmpty {
                        details.append("无法识别的字段: \(parseInfo.unrecognizedKeys.joined(separator: ", "))")
                    }
                    if !parseInfo.invalidValues.isEmpty {
                        details.append("无效数值: \(parseInfo.invalidValues.joined(separator: ", "))")
                    }
                    if parseInfo.record.values.isEmpty && parseInfo.unrecognizedKeys.isEmpty {
                        details.append("未找到任何有效的检测指标")
                    }
                    
                    failures.append(ParseFailure(
                        index: 1,
                        reason: "记录解析失败",
                        details: details
                    ))
                }
            }
            else {
                throw BloodTestError.decodingFailed
            }
        } catch let error as BloodTestError {
            throw error
        } catch {
            throw BloodTestError.decodingFailed
        }
        
        // 检查重复日期
        let existingRecords = try await loadRecords()
        var newRecords: [BloodTestRecord] = []
        var duplicateRecords: [BloodTestRecord] = []
        var matchingExisting: [BloodTestRecord] = []
        
        let calendar = Calendar.current
        
        for record in parsedRecords {
            // 检查是否有同一天的记录
            if let existing = existingRecords.first(where: { 
                calendar.isDate($0.date, inSameDayAs: record.date) 
            }) {
                duplicateRecords.append(record)
                matchingExisting.append(existing)
            } else {
                newRecords.append(record)
            }
        }
        
        return ImportResult(
            newRecords: newRecords,
            duplicateRecords: duplicateRecords,
            existingRecords: matchingExisting,
            failures: failures
        )
    }
    
    // MARK: - 保存导入的记录
    func saveImportedRecords(_ records: [BloodTestRecord], replaceDuplicates: Bool = false, duplicatesToReplace: [BloodTestRecord] = []) async throws {
        var allRecords = try await loadRecords()
        let calendar = Calendar.current
        
        // 如果替换重复记录，先删除旧的
        if replaceDuplicates {
            for duplicate in duplicatesToReplace {
                allRecords.removeAll { calendar.isDate($0.date, inSameDayAs: duplicate.date) }
            }
        }
        
        // 添加新记录
        allRecords.append(contentsOf: records)
        
        try await writeRecords(allRecords)
        self.records = allRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - 导入 JSON（兼容旧方法）
    func importFromJSON(_ jsonString: String) async throws -> BloodTestRecord? {
        let result = try await parseJSON(jsonString)
        
        if !result.newRecords.isEmpty {
            try await saveImportedRecords(result.newRecords)
            return result.newRecords.first
        }
        
        if !result.duplicateRecords.isEmpty {
            // 默认替换
            try await saveImportedRecords(result.duplicateRecords, replaceDuplicates: true, duplicatesToReplace: result.duplicateRecords)
            return result.duplicateRecords.first
        }
        
        return nil
    }
    
    // MARK: - 刷新数据
    func refresh() async {
        await loadRecordsFromDisk()
    }
}

// MARK: - 统计扩展
extension BloodTestKitManager {
    /// 获取指定指标的平均值
    func averageValue(for key: LabMetricKey, days: Int? = nil) -> Double? {
        let history = metricHistory(for: key, days: days)
        guard !history.isEmpty else { return nil }
        return history.map { $0.value }.reduce(0, +) / Double(history.count)
    }
    
    /// 获取指定指标的最大值
    func maxValue(for key: LabMetricKey, days: Int? = nil) -> Double? {
        let history = metricHistory(for: key, days: days)
        return history.map { $0.value }.max()
    }
    
    /// 获取指定指标的最小值
    func minValue(for key: LabMetricKey, days: Int? = nil) -> Double? {
        let history = metricHistory(for: key, days: days)
        return history.map { $0.value }.min()
    }
}

