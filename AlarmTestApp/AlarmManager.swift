import Foundation
import SwiftUI
import AVFoundation
import UserNotifications
import AudioToolbox

@MainActor
class AlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = AlarmManager()
    
    // Published states for UI
    @Published var isAlarmActive: Bool = false
    @Published var isAlarmRinging: Bool = false
    @Published var targetAlarmDate: Date? = nil
    @Published var remainingSeconds: Int = 0
    @Published var backgroundKeepAliveEnabled: Bool = true
    @Published var notificationAuthorized: Bool = false
    @Published var volumeLevel: Float = 1.0
    
    // Audio players
    private var alarmAudioPlayer: AVAudioPlayer?
    private var silentAudioPlayer: AVAudioPlayer?
    
    // Timers
    private var countdownTimer: Timer?
    private var heartbeatTimer: Timer?
    private var vibrationTimer: Timer?
    
    // Logger
    private let logger = LogManager.shared
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupAudioSession()
        checkNotificationPermission()
        setupSilentPlayer()
        setupAlarmPlayer()
    }
    
    // MARK: - Audio Session Configuration
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback category allows audio to play in background and bypass silent/mute switch
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            logger.log("AVAudioSession đã cấu hình Category: .playback (Xuyên chế độ im lặng)", level: .info)
        } catch {
            logger.log("Lỗi cấu hình AVAudioSession: \(error.localizedDescription)", level: .error)
        }
    }
    
    // MARK: - Permissions
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationAuthorized = (settings.authorizationStatus == .authorized)
                self?.logger.log("Quyền thông báo: \(settings.authorizationStatus == .authorized ? "ĐÃ CẤP" : "CHƯA CẤP")", level: .info)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationAuthorized = granted
                if granted {
                    self?.logger.log("Người dùng đã cấp quyền Thông báo", level: .info)
                } else if let error = error {
                    self?.logger.log("Lỗi xin quyền thông báo: \(error.localizedDescription)", level: .error)
                } else {
                    self?.logger.log("Người dùng từ chối quyền Thông báo", level: .warning)
                }
            }
        }
    }
    
    // MARK: - Audio Players Setup
    private func setupSilentPlayer() {
        // If silence.wav is in bundle, load it; otherwise create synthetic audio data
        if let url = Bundle.main.url(forResource: "silence", withExtension: "wav") {
            do {
                silentAudioPlayer = try AVAudioPlayer(contentsOf: url)
                silentAudioPlayer?.numberOfLoops = -1 // Loop infinitely
                silentAudioPlayer?.volume = 0.01 // Minimal inaudible volume to keep hardware active
                silentAudioPlayer?.prepareToPlay()
                logger.log("Đã tải tệp silence.wav thành công", level: .info)
            } catch {
                logger.log("Lỗi khởi tạo silent player: \(error.localizedDescription)", level: .warning)
            }
        } else {
            // Fallback: Generate 1 second of inaudible PCM silence
            if let silentData = generateSilenceWavData() {
                do {
                    silentAudioPlayer = try AVAudioPlayer(data: silentData)
                    silentAudioPlayer?.numberOfLoops = -1
                    silentAudioPlayer?.volume = 0.01
                    silentAudioPlayer?.prepareToPlay()
                    logger.log("Đã tạo luồng âm thanh tĩnh (Synthetic Silence) chạy nền", level: .info)
                } catch {
                    logger.log("Lỗi tạo Synthetic Silence: \(error.localizedDescription)", level: .warning)
                }
            }
        }
    }
    
    private func setupAlarmPlayer() {
        if let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") {
            do {
                alarmAudioPlayer = try AVAudioPlayer(contentsOf: url)
                alarmAudioPlayer?.numberOfLoops = -1 // Loop indefinitely until dismissed
                alarmAudioPlayer?.volume = 1.0
                alarmAudioPlayer?.prepareToPlay()
                logger.log("Đã tải tệp alarm.wav thành công", level: .info)
            } catch {
                logger.log("Lỗi tải tệp alarm.wav: \(error.localizedDescription)", level: .warning)
            }
        } else {
            // Fallback: Generate loud pulsating beep tone
            if let alarmData = generateAlarmBeepWavData() {
                do {
                    alarmAudioPlayer = try AVAudioPlayer(data: alarmData)
                    alarmAudioPlayer?.numberOfLoops = -1
                    alarmAudioPlayer?.volume = 1.0
                    alarmAudioPlayer?.prepareToPlay()
                    logger.log("Đã tạo chuông báo động tổng hợp (Synthetic Loud Beep)", level: .info)
                } catch {
                    logger.log("Lỗi tạo Synthetic Alarm: \(error.localizedDescription)", level: .warning)
                }
            }
        }
    }
    
    // MARK: - Alarm Scheduling & Testing
    func startQuickCountdown(seconds: Int) {
        cancelAlarm()
        
        let target = Date().addingTimeInterval(TimeInterval(seconds))
        targetAlarmDate = target
        remainingSeconds = seconds
        isAlarmActive = true
        
        logger.log("Bắt đầu đếm ngược TEST: \(seconds) giây (Hẹn lúc \(formatTime(target)))", level: .info)
        
        // 1. Schedule local notification as safety net
        scheduleLocalNotification(at: target, title: "⏰ BÁO THỨC TEST ĐẾN GIỜ!", body: "Hết thời gian đếm ngược \(seconds)s. Mở app để tắt chuông.")
        
        // 2. Start Keep-Alive silent audio if enabled
        if backgroundKeepAliveEnabled {
            startBackgroundKeepAlive()
        }
        
        // 3. Start countdown timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.remainingSeconds > 1 {
                    self.remainingSeconds -= 1
                } else {
                    self.remainingSeconds = 0
                    self.triggerAlarm()
                }
            }
        }
    }
    
    func setSpecificAlarm(date: Date) {
        cancelAlarm()
        
        var target = date
        if target <= Date() {
            // If selected time today has already passed, schedule for tomorrow
            target = Calendar.current.date(byAdding: .day, value: 1, to: target) ?? target
        }
        
        let diff = Int(target.timeIntervalSinceNow)
        targetAlarmDate = target
        remainingSeconds = diff
        isAlarmActive = true
        
        logger.log("Đã đặt báo thức lúc: \(formatTime(target)) (còn \(diff / 60) phút \(diff % 60) giây)", level: .info)
        
        scheduleLocalNotification(at: target, title: "⏰ BÁO THỨC ĐÃ ĐẾN GIỜ!", body: "Đồng hồ báo thức đang reo. Bấm vào đây để mở ứng dụng.")
        
        if backgroundKeepAliveEnabled {
            startBackgroundKeepAlive()
        }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let currentDiff = Int(target.timeIntervalSinceNow)
                if currentDiff > 0 {
                    self.remainingSeconds = currentDiff
                } else {
                    self.remainingSeconds = 0
                    self.triggerAlarm()
                }
            }
        }
    }
    
    // MARK: - Keep-Alive Audio & Heartbeat
    private func startBackgroundKeepAlive() {
        silentAudioPlayer?.play()
        logger.log("Đã kích hoạt Silent Audio Loop để giữ App không bị iOS Kill", level: .info)
        
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.logger.recordHeartbeat()
            }
        }
    }
    
    private func stopBackgroundKeepAlive() {
        silentAudioPlayer?.stop()
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    // MARK: - Alarm Trigger & Dismiss
    func triggerAlarm() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isAlarmActive = false
        isAlarmRinging = true
        
        logger.log("🚨 CHUÔNG BÁO THỨC ĐANG REO! 🚨", level: .alarm)
        
        // Ensure audio session is active and playback is forced
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.log("Lỗi kích hoạt AudioSession khi reo: \(error.localizedDescription)", level: .error)
        }
        
        // Stop silent player and start loud alarm player
        stopBackgroundKeepAlive()
        alarmAudioPlayer?.currentTime = 0
        alarmAudioPlayer?.play()
        
        // Start continuous haptic/vibration feedback
        startVibrations()
    }
    
    func dismissAlarm() {
        isAlarmRinging = false
        isAlarmActive = false
        remainingSeconds = 0
        targetAlarmDate = nil
        
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        stopBackgroundKeepAlive()
        alarmAudioPlayer?.stop()
        stopVibrations()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.log("Đã tắt báo thức", level: .info)
    }
    
    func snoozeAlarm(seconds: Int = 60) {
        logger.log("Báo lại (Snooze) sau \(seconds) giây", level: .info)
        dismissAlarm()
        startQuickCountdown(seconds: seconds)
    }
    
    func cancelAlarm() {
        dismissAlarm()
        logger.log("Đã huỷ toàn bộ lịch báo thức đang chờ", level: .info)
    }
    
    // MARK: - Haptics / Vibration Loop
    private func startVibrations() {
        stopVibrations()
        // Trigger immediate vibration
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
    
    private func stopVibrations() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
    
    // MARK: - Local Notification Scheduling
    private func scheduleLocalNotification(at targetDate: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
        content.interruptionLevel = .timeSensitive
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "ALARM_TEST_REQUEST", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.log("Lỗi tạo thông báo: \(error.localizedDescription)", level: .error)
                } else {
                    self?.logger.log("Đã lên lịch Thông báo cục bộ vào lúc: \(self?.formatTime(targetDate) ?? "")", level: .info)
                }
            }
        }
    }
    
    // MARK: - Notification Delegate
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even if app is in foreground
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            LogManager.shared.log("Người dùng tương tác với thông báo Báo Thức", level: .alarm)
            AlarmManager.shared.triggerAlarm()
        }
        completionHandler()
    }
    
    // MARK: - Helper Synthesized WAV Data
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func generateSilenceWavData() -> Data? {
        let sampleRate: Int32 = 44100
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let durationSeconds: Double = 1.0
        let numSamples = Int32(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * Int32(numChannels) * Int32(bitsPerSample / 8)
        
        var data = Data()
        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = dataSize + 36
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        // fmt subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size: Int32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1 // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var channels = numChannels
        data.append(Data(bytes: &channels, count: 2))
        var sRate = sampleRate
        data.append(Data(bytes: &sRate, count: 4))
        var byteRate = sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = Int16(numChannels * (bitsPerSample / 8))
        data.append(Data(bytes: &blockAlign, count: 2))
        var bps = bitsPerSample
        data.append(Data(bytes: &bps, count: 2))
        // data subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var dSize = dataSize
        data.append(Data(bytes: &dSize, count: 4))
        // Zero samples for silence
        let zeroSamples = [UInt8](repeating: 0, count: Int(dataSize))
        data.append(contentsOf: zeroSamples)
        
        return data
    }
    
    private func generateAlarmBeepWavData() -> Data? {
        let sampleRate: Int32 = 44100
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let durationSeconds: Double = 1.0
        let numSamples = Int32(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * Int32(numChannels) * Int32(bitsPerSample / 8)
        
        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = dataSize + 36
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size: Int32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var channels = numChannels
        data.append(Data(bytes: &channels, count: 2))
        var sRate = sampleRate
        data.append(Data(bytes: &sRate, count: 4))
        var byteRate = sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = Int16(numChannels * (bitsPerSample / 8))
        data.append(Data(bytes: &blockAlign, count: 2))
        var bps = bitsPerSample
        data.append(Data(bytes: &bps, count: 2))
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var dSize = dataSize
        data.append(Data(bytes: &dSize, count: 4))
        
        // Generate high-pitch pulsating alarm tone (880Hz alternating with 1760Hz)
        for i in 0..<numSamples {
            let t = Double(i) / Double(sampleRate)
            // 0.25s beep, 0.1s silence pattern
            let cycle = t.truncatingRemainder(dividingBy: 0.35)
            var sampleValue: Int16 = 0
            if cycle < 0.25 {
                let freq = (cycle < 0.125) ? 950.0 : 1400.0
                let wave = sin(2.0 * Double.pi * freq * t)
                sampleValue = Int16(wave * 28000.0) // Loud volume amplitude
            }
            var s = sampleValue
            data.append(Data(bytes: &s, count: 2))
        }
        
        return data
    }
}
