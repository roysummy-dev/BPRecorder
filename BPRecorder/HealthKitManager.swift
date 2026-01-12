//
//  HealthKitManager.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/11.
//

import Foundation
import HealthKit

// 血压记录数据模型
struct BloodPressureRecord: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let systolic: Double
    let diastolic: Double
    var heartRate: Double?
    // 存储原始样本的 UUID 用于删除
    let systolicSampleUUID: UUID?
    let diastolicSampleUUID: UUID?
    
    init(id: UUID = UUID(), date: Date, systolic: Double, diastolic: Double, heartRate: Double? = nil, systolicSampleUUID: UUID? = nil, diastolicSampleUUID: UUID? = nil) {
        self.id = id
        self.date = date
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.systolicSampleUUID = systolicSampleUUID
        self.diastolicSampleUUID = diastolicSampleUUID
    }
    
    // 血压状态
    var status: BPStatus {
        if systolic < 90 || diastolic < 60 {
            return .low
        } else if systolic < 120 && diastolic < 80 {
            return .normal
        } else if systolic < 140 || diastolic < 90 {
            return .elevated
        } else {
            return .high
        }
    }
    
    enum BPStatus: String {
        case low = "偏低"
        case normal = "正常"
        case elevated = "偏高"
        case high = "高血压"
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .normal: return "green"
            case .elevated: return "orange"
            case .high: return "red"
            }
        }
    }
    
    static func == (lhs: BloodPressureRecord, rhs: BloodPressureRecord) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var recentRecords: [BloodPressureRecord] = []
    @Published var allRecords: [BloodPressureRecord] = []
    
    // 血压类型
    private let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
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
        
        let systolicStatus = healthStore.authorizationStatus(for: systolicType)
        let diastolicStatus = healthStore.authorizationStatus(for: diastolicType)
        
        isAuthorized = systolicStatus == .sharingAuthorized && diastolicStatus == .sharingAuthorized
    }
    
    // 请求授权
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "此设备不支持健康数据"
            return
        }
        
        let typesToWrite: Set<HKSampleType> = [systolicType, diastolicType, heartRateType]
        let typesToRead: Set<HKObjectType> = [systolicType, diastolicType, heartRateType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            checkAuthorizationStatus()
            await fetchRecentRecords()
        } catch {
            authorizationError = "授权失败: \(error.localizedDescription)"
        }
    }
    
    // 保存血压数据
    func saveBloodPressure(systolic: Double, diastolic: Double, heartRate: Double? = nil, date: Date = Date()) async throws {
        // 创建血压样本
        let systolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: systolic)
        let diastolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: diastolic)
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicQuantity,
            start: date,
            end: date
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicQuantity,
            start: date,
            end: date
        )
        
        // 创建血压关联类型
        let bloodPressureType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
        
        let bloodPressureCorrelation = HKCorrelation(
            type: bloodPressureType,
            start: date,
            end: date,
            objects: [systolicSample, diastolicSample]
        )
        
        // 保存血压数据
        try await healthStore.save(bloodPressureCorrelation)
        
        // 如果有心率数据，也保存
        if let heartRate = heartRate, heartRate > 0 {
            let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: heartRate)
            let heartRateSample = HKQuantitySample(
                type: heartRateType,
                quantity: heartRateQuantity,
                start: date,
                end: date
            )
            try await healthStore.save(heartRateSample)
        }
        
        // 刷新数据
        await fetchRecentRecords()
    }
    
    // 删除血压记录
    func deleteRecord(_ record: BloodPressureRecord) async throws {
        guard isHealthKitAvailable else { return }
        
        // 根据时间查找并删除对应的样本
        let predicate = HKQuery.predicateForSamples(
            withStart: record.date.addingTimeInterval(-1),
            end: record.date.addingTimeInterval(1),
            options: .strictStartDate
        )
        
        // 删除收缩压样本
        let systolicSamples = await fetchSamplesForDeletion(type: systolicType, predicate: predicate)
        for sample in systolicSamples {
            try await healthStore.delete(sample)
        }
        
        // 删除舒张压样本
        let diastolicSamples = await fetchSamplesForDeletion(type: diastolicType, predicate: predicate)
        for sample in diastolicSamples {
            try await healthStore.delete(sample)
        }
        
        // 从本地列表移除
        allRecords.removeAll { $0.id == record.id }
        recentRecords.removeAll { $0.id == record.id }
    }
    
    // 获取用于删除的样本
    private func fetchSamplesForDeletion(type: HKSampleType, predicate: NSPredicate) async -> [HKSample] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    // 获取最近的血压记录（最近7天）
    func fetchRecentRecords() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        let records = await fetchBloodPressureRecords(from: startDate, to: endDate)
        self.recentRecords = records
    }
    
    // 获取所有血压记录
    func fetchAllRecords() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate)!
        
        let records = await fetchBloodPressureRecords(from: startDate, to: endDate)
        self.allRecords = records
    }
    
    // 从 HealthKit 获取血压记录（分别读取收缩压和舒张压，然后匹配）
    private func fetchBloodPressureRecords(from startDate: Date, to endDate: Date) async -> [BloodPressureRecord] {
        guard isHealthKitAvailable else { return [] }
        
        // 分别获取收缩压和舒张压数据
        async let systolicSamples = fetchQuantitySamples(type: systolicType, from: startDate, to: endDate)
        async let diastolicSamples = fetchQuantitySamples(type: diastolicType, from: startDate, to: endDate)
        
        let (systolics, diastolics) = await (systolicSamples, diastolicSamples)
        
        // 根据时间戳匹配收缩压和舒张压
        var records: [BloodPressureRecord] = []
        
        for systolicSample in systolics {
            // 查找时间戳相同的舒张压记录
            if let diastolicSample = diastolics.first(where: { 
                abs($0.startDate.timeIntervalSince(systolicSample.startDate)) < 1 
            }) {
                let systolicValue = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
                let diastolicValue = diastolicSample.quantity.doubleValue(for: .millimeterOfMercury())
                
                let record = BloodPressureRecord(
                    date: systolicSample.startDate,
                    systolic: systolicValue,
                    diastolic: diastolicValue,
                    systolicSampleUUID: systolicSample.uuid,
                    diastolicSampleUUID: diastolicSample.uuid
                )
                records.append(record)
            }
        }
        
        // 按日期降序排序
        return records.sorted { $0.date > $1.date }
    }
    
    // 获取指定类型的样本数据
    private func fetchQuantitySamples(type: HKQuantityType, from startDate: Date, to endDate: Date) async -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
}


