//
//  WeightKitManager.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import Foundation
import HealthKit

// 体重记录数据模型
struct WeightRecord: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let weight: Double // 单位：千克
    let sampleUUID: UUID?
    
    init(id: UUID = UUID(), date: Date, weight: Double, sampleUUID: UUID? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
        self.sampleUUID = sampleUUID
    }
    
    // 体重状态（基于 BMI 估算，假设身高 170cm）
    var status: WeightStatus {
        // 简单的体重范围判断
        if weight < 45 {
            return .underweight
        } else if weight < 65 {
            return .normal
        } else if weight < 80 {
            return .overweight
        } else {
            return .obese
        }
    }
    
    enum WeightStatus: String {
        case underweight = "偏轻"
        case normal = "正常"
        case overweight = "偏重"
        case obese = "肥胖"
        
        var color: String {
            switch self {
            case .underweight: return "blue"
            case .normal: return "green"
            case .overweight: return "orange"
            case .obese: return "red"
            }
        }
    }
    
    static func == (lhs: WeightRecord, rhs: WeightRecord) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class WeightKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var recentRecords: [WeightRecord] = []
    @Published var allRecords: [WeightRecord] = []
    
    // 体重类型
    private let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    
    init() {
        checkAuthorizationStatus()
    }
    
    // 检查 HealthKit 是否可用
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // 检查授权状态
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            authorizationError = "此设备不支持健康数据"
            return
        }
        
        let status = healthStore.authorizationStatus(for: weightType)
        isAuthorized = status == .sharingAuthorized
    }
    
    // 请求授权
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "此设备不支持健康数据"
            return
        }
        
        let typesToWrite: Set<HKSampleType> = [weightType]
        let typesToRead: Set<HKObjectType> = [weightType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            checkAuthorizationStatus()
            await fetchRecentRecords()
        } catch {
            authorizationError = "授权失败: \(error.localizedDescription)"
        }
    }
    
    // 保存体重数据
    func saveWeight(_ weight: Double, date: Date = Date()) async throws {
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(weightSample)
        
        // 刷新数据
        await fetchRecentRecords()
    }
    
    // 删除体重记录
    func deleteRecord(_ record: WeightRecord) async throws {
        guard isHealthKitAvailable else { return }
        
        // 根据时间查找并删除对应的样本
        let predicate = HKQuery.predicateForSamples(
            withStart: record.date.addingTimeInterval(-1),
            end: record.date.addingTimeInterval(1),
            options: .strictStartDate
        )
        
        let samples = await fetchSamplesForDeletion(predicate: predicate)
        for sample in samples {
            try await healthStore.delete(sample)
        }
        
        // 从本地列表移除
        allRecords.removeAll { $0.id == record.id }
        recentRecords.removeAll { $0.id == record.id }
    }
    
    // 获取用于删除的样本
    private func fetchSamplesForDeletion(predicate: NSPredicate) async -> [HKSample] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    // 获取最近的体重记录（最近30天）
    func fetchRecentRecords() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        let records = await fetchWeightRecords(from: startDate, to: endDate)
        self.recentRecords = records
    }
    
    // 获取所有体重记录
    func fetchAllRecords() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate)!
        
        let records = await fetchWeightRecords(from: startDate, to: endDate)
        self.allRecords = records
    }
    
    // 从 HealthKit 获取体重记录
    private func fetchWeightRecords(from startDate: Date, to endDate: Date) async -> [WeightRecord] {
        guard isHealthKitAvailable else { return [] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let records = quantitySamples.map { sample in
                    WeightRecord(
                        date: sample.startDate,
                        weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                        sampleUUID: sample.uuid
                    )
                }
                
                continuation.resume(returning: records)
            }
            
            healthStore.execute(query)
        }
    }
    
    // 获取体重变化
    var weightChange: Double? {
        guard recentRecords.count >= 2 else { return nil }
        let sorted = recentRecords.sorted { $0.date > $1.date }
        return sorted[0].weight - sorted[1].weight
    }
    
    // 获取最近体重
    var latestWeight: Double? {
        recentRecords.sorted { $0.date > $1.date }.first?.weight
    }
}

