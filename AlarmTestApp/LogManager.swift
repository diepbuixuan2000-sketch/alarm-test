import Foundation
import SwiftUI
import Combine

enum LogLevel: String, CaseIterable {
    case info = "INFO"
    case warning = "WARN"
    case alarm = "ALARM"
    case heartbeat = "BEAT"
    case error = "ERR"
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .alarm: return .red
        case .heartbeat: return .green
        case .error: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .alarm: return "bell.badge.fill"
        case .heartbeat: return "waveform.path.ecg"
        case .error: return "xmark.octagon.fill"
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

@MainActor
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var entries: [LogEntry] = []
    @Published var heartbeatCount: Int = 0
    
    private init() {
        log("Hệ thống Log đã khởi động", level: .info)
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), message: message, level: level)
        entries.append(entry)
        // Keep last 150 entries to preserve memory
        if entries.count > 150 {
            entries.removeFirst(entries.count - 150)
        }
        print("[\(entry.formattedTime)] [\(level.rawValue)] \(message)")
    }
    
    func recordHeartbeat() {
        heartbeatCount += 1
        if heartbeatCount % 5 == 0 {
            log("Nhịp tim ngầm #\(heartbeatCount) (App vẫn sống trong nền)", level: .heartbeat)
        }
    }
    
    func clear() {
        entries.removeAll()
        heartbeatCount = 0
        log("Đã xoá toàn bộ log", level: .info)
    }
    
    func exportText() -> String {
        entries.map { "[\($0.formattedTime)] [\($0.level.rawValue)] \($0.message)" }
            .joined(separator: "\n")
    }
}
