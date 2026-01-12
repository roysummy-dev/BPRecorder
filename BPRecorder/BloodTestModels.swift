//
//  BloodTestModels.swift
//  BPRecorder
//
//  Created by shibofang on 2026/1/12.
//

import Foundation
import SwiftUI

// MARK: - 指标分类
enum LabMetricCategory: String, Codable, CaseIterable {
    case index = "综合指数"
    case bloodRoutine = "血常规"
    case biochemistry = "生化"
    case tumorMarker = "肿瘤标志物"
    
    var sortOrder: Int {
        switch self {
        case .index: return 0
        case .bloodRoutine: return 1
        case .biochemistry: return 2
        case .tumorMarker: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .index: return .purple
        case .bloodRoutine: return .red
        case .biochemistry: return .orange
        case .tumorMarker: return .blue
        }
    }
}

// MARK: - 指标枚举
enum LabMetricKey: String, Codable, CaseIterable, Identifiable {
    // 综合指数
    case nlr = "nlr"
    case plr = "plr"
    case lmr = "lmr"
    case pni = "pni"
    
    // 血常规 - 白细胞系
    case wbc = "wbc"
    case neutPercent = "neutPercent"
    case lymphPercent = "lymphPercent"
    case monoPercent = "monoPercent"
    case eoPercent = "eoPercent"
    case basoPercent = "basoPercent"
    case neutAbs = "neutAbs"
    case lymphAbs = "lymphAbs"
    case monoAbs = "monoAbs"
    case eoAbs = "eoAbs"
    case basoAbs = "basoAbs"
    
    // 血常规 - 红细胞系
    case rbc = "rbc"
    case hgb = "hgb"
    case hct = "hct"
    case mcv = "mcv"
    case mch = "mch"
    case mchc = "mchc"
    case rdwCv = "rdwCv"
    case rdwSd = "rdwSd"
    
    // 血常规 - 血小板系
    case plt = "plt"
    case mpv = "mpv"
    case pct = "pct"
    case pLcr = "pLcr"
    
    // 生化 - 肝功能
    case tbil = "tbil"
    case dbil = "dbil"
    case ibil = "ibil"
    case tp = "tp"
    case alb = "alb"
    case glob = "glob"
    case agRatio = "agRatio"
    case alt = "alt"
    case ast = "ast"
    case astAltRatio = "astAltRatio"
    case alp = "alp"
    case ggt = "ggt"
    
    // 生化 - 肾功能
    case bun = "bun"
    case uricAcid = "uricAcid"
    case creatinine = "creatinine"
    case egfr = "egfr"
    
    // 肿瘤标志物
    case cea = "cea"
    case ca125 = "ca125"
    case ca199 = "ca199"
    
    var id: String { rawValue }
    
    // MARK: - 中文名称
    var displayName: String {
        switch self {
        case .nlr: return "NLR"
        case .plr: return "PLR"
        case .lmr: return "LMR"
        case .pni: return "PNI"
        case .wbc: return "白细胞计数"
        case .neutPercent: return "中性粒细胞百分数"
        case .lymphPercent: return "淋巴细胞百分数"
        case .monoPercent: return "单核细胞百分数"
        case .eoPercent: return "嗜酸性粒细胞百分数"
        case .basoPercent: return "嗜碱性粒细胞百分数"
        case .neutAbs: return "中性粒细胞绝对值"
        case .lymphAbs: return "淋巴细胞绝对值"
        case .monoAbs: return "单核细胞绝对值"
        case .eoAbs: return "嗜酸性粒细胞绝对值"
        case .basoAbs: return "嗜碱性粒细胞绝对值"
        case .rbc: return "红细胞计数"
        case .hgb: return "血红蛋白"
        case .hct: return "红细胞比容"
        case .mcv: return "平均红细胞体积（MCV）"
        case .mch: return "平均红细胞血红蛋白（MCH）"
        case .mchc: return "平均红细胞血红蛋白浓度（MCHC）"
        case .rdwCv: return "RBC体积分布宽度（RDW-CV）"
        case .rdwSd: return "RBC体积分布宽度（RDW-SD）"
        case .plt: return "血小板计数"
        case .mpv: return "平均血小板体积"
        case .pct: return "血小板比容"
        case .pLcr: return "大血小板比例"
        case .tbil: return "总胆红素"
        case .dbil: return "直接胆红素"
        case .ibil: return "间接胆红素"
        case .tp: return "总蛋白"
        case .alb: return "白蛋白"
        case .glob: return "球蛋白"
        case .agRatio: return "白球比"
        case .alt: return "丙氨酸氨基转移酶（ALT）谷丙"
        case .ast: return "门冬氨酸氨基转移酶（AST）"
        case .astAltRatio: return "谷草/谷丙比值"
        case .alp: return "碱性磷酸酶（ALP）"
        case .ggt: return "谷氨酰转肽酶（GGT）"
        case .bun: return "尿素氮（BUN）"
        case .uricAcid: return "尿酸"
        case .creatinine: return "肌酐"
        case .egfr: return "肾小球滤过率（eGFR）"
        case .cea: return "癌胚抗原（CEA）"
        case .ca125: return "糖类抗原 CA125"
        case .ca199: return "糖类抗原 CA199"
        }
    }
    
    // MARK: - 简短名称（用于图表）
    var shortName: String {
        switch self {
        case .nlr: return "NLR"
        case .plr: return "PLR"
        case .lmr: return "LMR"
        case .pni: return "PNI"
        case .wbc: return "WBC"
        case .neutPercent: return "NEUT%"
        case .lymphPercent: return "LYM%"
        case .monoPercent: return "MONO%"
        case .eoPercent: return "EO%"
        case .basoPercent: return "BASO%"
        case .neutAbs: return "NEUT#"
        case .lymphAbs: return "LYM#"
        case .monoAbs: return "MONO#"
        case .eoAbs: return "EO#"
        case .basoAbs: return "BASO#"
        case .rbc: return "RBC"
        case .hgb: return "HGB"
        case .hct: return "HCT"
        case .mcv: return "MCV"
        case .mch: return "MCH"
        case .mchc: return "MCHC"
        case .rdwCv: return "RDW-CV"
        case .rdwSd: return "RDW-SD"
        case .plt: return "PLT"
        case .mpv: return "MPV"
        case .pct: return "PCT"
        case .pLcr: return "P-LCR"
        case .tbil: return "TBIL"
        case .dbil: return "DBIL"
        case .ibil: return "IBIL"
        case .tp: return "TP"
        case .alb: return "ALB"
        case .glob: return "GLOB"
        case .agRatio: return "A/G"
        case .alt: return "ALT"
        case .ast: return "AST"
        case .astAltRatio: return "AST/ALT"
        case .alp: return "ALP"
        case .ggt: return "GGT"
        case .bun: return "BUN"
        case .uricAcid: return "UA"
        case .creatinine: return "Cr"
        case .egfr: return "eGFR"
        case .cea: return "CEA"
        case .ca125: return "CA125"
        case .ca199: return "CA199"
        }
    }
    
    // MARK: - 单位
    var unit: String {
        switch self {
        case .nlr, .plr, .lmr, .pni, .agRatio, .astAltRatio:
            return ""
        case .wbc, .neutAbs, .lymphAbs, .monoAbs, .eoAbs, .basoAbs:
            return "10⁹/L"
        case .neutPercent, .lymphPercent, .monoPercent, .eoPercent, .basoPercent, .hct, .rdwCv, .pct, .pLcr:
            return "%"
        case .rbc:
            return "10¹²/L"
        case .hgb, .mchc, .tp, .alb, .glob:
            return "g/L"
        case .mcv, .mpv:
            return "fL"
        case .mch:
            return "pg"
        case .rdwSd:
            return ""
        case .plt:
            return "10⁹/L"
        case .tbil, .dbil, .ibil, .uricAcid, .creatinine:
            return "μmol/L"
        case .alt, .ast, .alp, .ggt:
            return "U/L"
        case .bun:
            return "mmol/L"
        case .egfr:
            return "ml/min"
        case .cea:
            return "ng/ml"
        case .ca125, .ca199:
            return "U/ml"
        }
    }
    
    // MARK: - 正常范围文本
    var normalRangeText: String {
        switch self {
        case .nlr:
            return "1–3\n>3表示炎症增加"
        case .plr:
            return "健康人：< 150\n150–300：轻度炎症"
        case .lmr:
            return "> 4：免疫状态良好\n< 2–3：往往提示不良预后、炎症、肿瘤负荷大"
        case .pni:
            return "PNI=10×白蛋白(g/dL)+0.005×淋巴细胞(/mm³)\n> 50：营养状况极佳\n45–50：可接受\n< 40：有营养不良/免疫弱化风险"
        case .wbc:
            return "3.5–9.5"
        case .neutPercent:
            return "40–75"
        case .lymphPercent:
            return "20–50"
        case .monoPercent:
            return "3–10"
        case .eoPercent:
            return "0.4–8"
        case .basoPercent:
            return "0–1"
        case .neutAbs:
            return "1.8–6.3"
        case .lymphAbs:
            return "1.1–3.2"
        case .monoAbs:
            return "0.1–0.6"
        case .eoAbs:
            return "0.02–0.52"
        case .basoAbs:
            return "0–0.06"
        case .rbc:
            return "4.3–5.8"
        case .hgb:
            return "130–175"
        case .hct:
            return "40–50"
        case .mcv:
            return "82–100"
        case .mch:
            return "27–34"
        case .mchc:
            return "316–354"
        case .rdwCv:
            return "11–16"
        case .rdwSd:
            return "39–52.3"
        case .plt:
            return "125–350"
        case .mpv:
            return "9–13"
        case .pct:
            return "0.11–0.31"
        case .pLcr:
            return "17.5–42.3"
        case .tbil:
            return "3.4–20.5"
        case .dbil:
            return "0–8.6"
        case .ibil:
            return "3–19"
        case .tp:
            return "65–85"
        case .alb:
            return "40–55"
        case .glob:
            return "20–40"
        case .agRatio:
            return "1.2–2.4"
        case .alt:
            return "9–50"
        case .ast:
            return "15–40"
        case .astAltRatio:
            return "—"
        case .alp:
            return "30–120"
        case .ggt:
            return "10–60"
        case .bun:
            return "1.7–8.3"
        case .uricAcid:
            return "208–428"
        case .creatinine:
            return "58–110"
        case .egfr:
            return ">90"
        case .cea:
            return "<5.0"
        case .ca125:
            return "<35"
        case .ca199:
            return "<30"
        }
    }
    
    // MARK: - 分类
    var category: LabMetricCategory {
        switch self {
        case .nlr, .plr, .lmr, .pni:
            return .index
        case .wbc, .neutPercent, .lymphPercent, .monoPercent, .eoPercent, .basoPercent,
             .neutAbs, .lymphAbs, .monoAbs, .eoAbs, .basoAbs,
             .rbc, .hgb, .hct, .mcv, .mch, .mchc, .rdwCv, .rdwSd,
             .plt, .mpv, .pct, .pLcr:
            return .bloodRoutine
        case .tbil, .dbil, .ibil, .tp, .alb, .glob, .agRatio,
             .alt, .ast, .astAltRatio, .alp, .ggt,
             .bun, .uricAcid, .creatinine, .egfr:
            return .biochemistry
        case .cea, .ca125, .ca199:
            return .tumorMarker
        }
    }
    
    // MARK: - 是否为重点指标
    var isKeyMetric: Bool {
        switch self {
        case .wbc, .neutAbs, .hgb, .plt:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 排序顺序
    var sortOrder: Int {
        switch self {
        case .nlr: return 0
        case .plr: return 1
        case .lmr: return 2
        case .pni: return 3
        case .wbc: return 10
        case .neutPercent: return 11
        case .lymphPercent: return 12
        case .monoPercent: return 13
        case .eoPercent: return 14
        case .basoPercent: return 15
        case .neutAbs: return 16
        case .lymphAbs: return 17
        case .monoAbs: return 18
        case .eoAbs: return 19
        case .basoAbs: return 20
        case .rbc: return 30
        case .hgb: return 31
        case .hct: return 32
        case .mcv: return 33
        case .mch: return 34
        case .mchc: return 35
        case .rdwCv: return 36
        case .rdwSd: return 37
        case .plt: return 40
        case .mpv: return 41
        case .pct: return 42
        case .pLcr: return 43
        case .tbil: return 50
        case .dbil: return 51
        case .ibil: return 52
        case .tp: return 53
        case .alb: return 54
        case .glob: return 55
        case .agRatio: return 56
        case .alt: return 57
        case .ast: return 58
        case .astAltRatio: return 59
        case .alp: return 60
        case .ggt: return 61
        case .bun: return 70
        case .uricAcid: return 71
        case .creatinine: return 72
        case .egfr: return 73
        case .cea: return 80
        case .ca125: return 81
        case .ca199: return 82
        }
    }
    
    // MARK: - 图表颜色
    var chartColor: Color {
        switch self {
        case .wbc: return .blue
        case .neutAbs: return .green
        case .hgb: return .red
        case .plt: return .purple
        default: return category.color
        }
    }
    
    // MARK: - 从中文名称映射
    static func fromChineseName(_ name: String) -> LabMetricKey? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        let mapping: [String: LabMetricKey] = [
            "NLR": .nlr,
            "PLR": .plr,
            "LMR": .lmr,
            "PNI": .pni,
            "白细胞计数": .wbc,
            "中性粒细胞百分数": .neutPercent,
            "淋巴细胞百分数": .lymphPercent,
            "单核细胞百分数": .monoPercent,
            "嗜酸性粒细胞百分数": .eoPercent,
            "嗜碱性粒细胞百分数": .basoPercent,
            "中性粒细胞绝对值": .neutAbs,
            "淋巴细胞绝对值": .lymphAbs,
            "单核细胞绝对值": .monoAbs,
            "嗜酸性粒细胞绝对值": .eoAbs,
            "嗜碱性粒细胞绝对值": .basoAbs,
            "红细胞计数": .rbc,
            "血红蛋白": .hgb,
            "红细胞比容": .hct,
            "平均红细胞体积（MCV）": .mcv,
            "平均红细胞血红蛋白（MCH）": .mch,
            "平均红细胞血红蛋白浓度（MCHC）": .mchc,
            "RBC体积分布宽度（RDW-CV）": .rdwCv,
            "RBC体积分布宽度（RDW-SD）": .rdwSd,
            "血小板计数": .plt,
            "平均血小板体积": .mpv,
            "血小板比容": .pct,
            "大血小板比例": .pLcr,
            "总胆红素": .tbil,
            "直接胆红素": .dbil,
            "间接胆红素": .ibil,
            "总蛋白": .tp,
            "白蛋白": .alb,
            "球蛋白": .glob,
            "白球比": .agRatio,
            "丙氨酸氨基转移酶（ALT）谷丙": .alt,
            "门冬氨酸氨基转移酶（AST）": .ast,
            "谷草/谷丙比值": .astAltRatio,
            "碱性磷酸酶（ALP）": .alp,
            "谷氨酰转肽酶（GGT）": .ggt,
            "尿素氮（BUN）": .bun,
            "尿酸": .uricAcid,
            "肌酐": .creatinine,
            "肾小球滤过率（eGFR）": .egfr,
            "癌胚抗原（CEA）": .cea,
            "糖类抗原 CA125": .ca125,
            "糖类抗原 CA199": .ca199
        ]
        
        return mapping[trimmed]
    }
    
    // MARK: - 按分类分组
    static var groupedByCategory: [LabMetricCategory: [LabMetricKey]] {
        var result: [LabMetricCategory: [LabMetricKey]] = [:]
        for category in LabMetricCategory.allCases {
            result[category] = allCases.filter { $0.category == category }.sorted { $0.sortOrder < $1.sortOrder }
        }
        return result
    }
    
    // MARK: - 重点指标
    static var keyMetrics: [LabMetricKey] {
        [.wbc, .neutAbs, .hgb, .plt]
    }
}

// MARK: - 事件标签
struct EventTag: Codable, Hashable {
    var scheme: String?    // 治疗方案，如 FOLFIRI
    var cycle: Int?        // 周期，如 2
    var day: Int?          // 天数，如 11
    var rawTokens: [String] // 其他标签
    
    init(scheme: String? = nil, cycle: Int? = nil, day: Int? = nil, rawTokens: [String] = []) {
        self.scheme = scheme
        self.cycle = cycle
        self.day = day
        self.rawTokens = rawTokens
    }
    
    // 从 event 字符串解析
    static func parse(from event: String) -> EventTag {
        var scheme: String?
        var cycle: Int?
        var day: Int?
        var rawTokens: [String] = []
        
        // 使用正则表达式解析
        let schemePattern = "^([A-Z]+)"
        let cyclePattern = "C(\\d+)"
        let dayPattern = "D(\\d+)"
        
        // 提取方案名
        if let schemeMatch = event.range(of: schemePattern, options: .regularExpression) {
            scheme = String(event[schemeMatch])
        }
        
        // 提取周期
        if let cycleMatch = event.range(of: cyclePattern, options: .regularExpression) {
            let cycleStr = String(event[cycleMatch])
            if let num = Int(cycleStr.dropFirst()) {
                cycle = num
            }
        }
        
        // 提取天数
        if let dayMatch = event.range(of: dayPattern, options: .regularExpression) {
            let dayStr = String(event[dayMatch])
            if let num = Int(dayStr.dropFirst()) {
                day = num
            }
        }
        
        // 提取其他文本作为标签
        var remainingText = event
        if let scheme = scheme {
            remainingText = remainingText.replacingOccurrences(of: scheme, with: "")
        }
        remainingText = remainingText.replacingOccurrences(of: "C\\d+", with: "", options: .regularExpression)
        remainingText = remainingText.replacingOccurrences(of: "D\\d+", with: "", options: .regularExpression)
        
        let tokens = remainingText.components(separatedBy: CharacterSet.whitespaces)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        if !tokens.isEmpty {
            rawTokens = tokens
        }
        
        return EventTag(scheme: scheme, cycle: cycle, day: day, rawTokens: rawTokens)
    }
    
    var displayText: String {
        var parts: [String] = []
        if let scheme = scheme { parts.append(scheme) }
        if let cycle = cycle { parts.append("C\(cycle)") }
        if let day = day { parts.append("D\(day)") }
        parts.append(contentsOf: rawTokens)
        return parts.joined(separator: " ")
    }
}

// MARK: - 附件（预留）
struct Attachment: Codable, Hashable {
    var id: UUID
    var fileName: String
    var filePath: String
    var type: String  // image, pdf, etc.
    
    init(id: UUID = UUID(), fileName: String, filePath: String, type: String) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.type = type
    }
}

// MARK: - 血液检测记录
struct BloodTestRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var event: String
    var tags: EventTag
    var values: [String: Double]  // 使用 String 作为 key 以便 JSON 序列化
    var notes: String?
    var attachments: [Attachment]?
    
    init(id: UUID = UUID(), date: Date, event: String = "", values: [LabMetricKey: Double] = [:], notes: String? = nil, attachments: [Attachment]? = nil) {
        self.id = id
        self.date = date
        self.event = event
        self.tags = EventTag.parse(from: event)
        self.values = Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) })
        self.notes = notes
        self.attachments = attachments
    }
    
    // 便捷访问器
    func value(for key: LabMetricKey) -> Double? {
        values[key.rawValue]
    }
    
    mutating func setValue(_ value: Double?, for key: LabMetricKey) {
        if let value = value {
            values[key.rawValue] = value
        } else {
            values.removeValue(forKey: key.rawValue)
        }
    }
    
    // 获取所有非空指标
    var presentKeys: [LabMetricKey] {
        values.keys.compactMap { LabMetricKey(rawValue: $0) }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // 重点指标摘要
    var keyMetricsSummary: String {
        let keys = LabMetricKey.keyMetrics
        let parts = keys.map { key -> String in
            if let value = value(for: key) {
                return "\(key.shortName): \(formatValue(value))"
            } else {
                return "\(key.shortName): --"
            }
        }
        return parts.joined(separator: " | ")
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    // 更新 event 时同步更新 tags
    mutating func updateEvent(_ newEvent: String) {
        event = newEvent
        tags = EventTag.parse(from: newEvent)
    }
    
    static func == (lhs: BloodTestRecord, rhs: BloodTestRecord) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - 自定义日期编解码
    enum CodingKeys: String, CodingKey {
        case id, date, event, tags, values, notes, attachments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        // 日期解码：支持 yyyy-MM-dd 格式
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let parsedDate = formatter.date(from: dateString) {
            date = parsedDate
        } else {
            date = Date()
        }
        
        event = try container.decode(String.self, forKey: .event)
        tags = try container.decodeIfPresent(EventTag.self, forKey: .tags) ?? EventTag.parse(from: event)
        values = try container.decode([String: Double].self, forKey: .values)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        // 日期编码：yyyy-MM-dd 格式
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        try container.encode(dateString, forKey: .date)
        
        try container.encode(event, forKey: .event)
        try container.encode(tags, forKey: .tags)
        try container.encode(values, forKey: .values)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(attachments, forKey: .attachments)
    }
}

// MARK: - JSON 解析辅助
// MARK: - 解析信息
struct ParseInfo {
    var record: BloodTestRecord
    var unrecognizedKeys: [String]    // 无法识别的字段名
    var invalidValues: [String]       // 无法解析为数值的字段
}

extension BloodTestRecord {
    /// 从中文 JSON 字典解析
    static func parse(from jsonDict: [String: String], defaultDate: Date = Date()) -> BloodTestRecord {
        return parseWithInfo(from: jsonDict, defaultDate: defaultDate).record
    }
    
    /// 从中文 JSON 字典解析，返回详细信息
    static func parseWithInfo(from jsonDict: [String: String], defaultDate: Date = Date()) -> ParseInfo {
        var values: [LabMetricKey: Double] = [:]
        var event = ""
        var date = defaultDate
        var unrecognizedKeys: [String] = []
        var invalidValues: [String] = []
        
        // 忽略的字段（非指标字段）
        let ignoredKeys = Set(["EVENT", "日期"])
        
        for (key, valueStr) in jsonDict {
            let trimmedKey = key.trimmingCharacters(in: .whitespaces)
            let trimmedValue = valueStr.trimmingCharacters(in: .whitespaces)
            
            // 跳过空值
            if trimmedValue.isEmpty || trimmedValue == "-" {
                continue
            }
            
            if trimmedKey == "EVENT" {
                event = trimmedValue
            } else if trimmedKey == "日期" {
                // 解析日期，如 "12.19"
                if let parsedDate = parseDate(trimmedValue) {
                    date = parsedDate
                }
            } else if let metricKey = LabMetricKey.fromChineseName(trimmedKey) {
                // 解析数值
                if let value = parseDouble(trimmedValue) {
                    values[metricKey] = value
                } else {
                    invalidValues.append("\(trimmedKey)=\(trimmedValue)")
                }
            } else if !ignoredKeys.contains(trimmedKey) {
                // 无法识别的字段
                unrecognizedKeys.append(trimmedKey)
            }
        }
        
        let record = BloodTestRecord(date: date, event: event, values: values)
        return ParseInfo(
            record: record,
            unrecognizedKeys: unrecognizedKeys,
            invalidValues: invalidValues
        )
    }
    
    private static func parseDate(_ str: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        // 尝试多种日期格式
        
        // 格式 1: yyyy-mm-dd 或 yyyy/mm/dd
        if str.contains("-") || str.contains("/") {
            let separator: Character = str.contains("-") ? "-" : "/"
            let parts = str.split(separator: separator)
            
            if parts.count == 3 {
                // yyyy-mm-dd 或 yy-mm-dd
                if let yearPart = Int(parts[0]),
                   let month = Int(parts[1]),
                   let day = Int(parts[2]) {
                    var year = yearPart
                    // 处理 yy-mm-dd 格式（两位数年份）
                    if year < 100 {
                        year = 2000 + year
                    }
                    
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents.month = month
                    dateComponents.day = day
                    
                    if let date = calendar.date(from: dateComponents) {
                        // 如果日期大于当前日期，年份往前推一年
                        if date > now {
                            dateComponents.year = year - 1
                            return calendar.date(from: dateComponents)
                        }
                        return date
                    }
                }
            } else if parts.count == 2 {
                // mm-dd 格式
                if let month = Int(parts[0]),
                   let day = Int(parts[1]) {
                    var dateComponents = DateComponents()
                    dateComponents.year = currentYear
                    dateComponents.month = month
                    dateComponents.day = day
                    
                    if let date = calendar.date(from: dateComponents) {
                        // 如果日期大于当前日期，年份往前推一年
                        if date > now {
                            dateComponents.year = currentYear - 1
                            return calendar.date(from: dateComponents)
                        }
                        return date
                    }
                }
            }
        }
        
        // 格式 2: mm.dd（原有格式）
        let dotComponents = str.split(separator: ".")
        if dotComponents.count == 2,
           let month = Int(dotComponents[0]),
           let day = Int(dotComponents[1]) {
            var dateComponents = DateComponents()
            dateComponents.year = currentYear
            dateComponents.month = month
            dateComponents.day = day
            
            if let date = calendar.date(from: dateComponents) {
                // 如果日期大于当前日期，年份往前推一年
                if date > now {
                    dateComponents.year = currentYear - 1
                    return calendar.date(from: dateComponents)
                }
                return date
            }
        }
        
        return nil
    }
    
    private static func parseDouble(_ str: String) -> Double? {
        let cleaned = str.trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

