import SwiftUI

struct ContentView: View {
    @StateObject private var alarmManager = AlarmManager.shared
    @StateObject private var logger = LogManager.shared
    
    @State private var selectedDate: Date = Date().addingTimeInterval(300) // Default +5 min
    @State private var currentTime = Date()
    @State private var showingCopiedToast = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Time & Permission Header
                        headerCard
                        
                        // Active Countdown Banner (if active)
                        if alarmManager.isAlarmActive {
                            activeCountdownCard
                        }
                        
                        // Quick Countdown Test Presets
                        quickTestCard
                        
                        // Custom Alarm Time Picker
                        customAlarmCard
                        
                        // Background Keep-Alive Controls
                        settingsCard
                        
                        // Real-time Event & Diagnostic Logs
                        logsConsoleCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                
                // Toast notification when logs are copied
                if showingCopiedToast {
                    VStack {
                        Spacer()
                        Text("Đã sao chép Log vào bộ nhớ tạm")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.bottom, 20)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("iOS Alarm Tester")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        alarmManager.triggerAlarm()
                    }) {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .onReceive(timer) { input in
                currentTime = input
            }
            // Fullscreen ringing alarm view
            .fullScreenCover(isPresented: $alarmManager.isAlarmRinging) {
                AlarmRingingView()
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(formattedClock(currentTime))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                // Notification Status Badge
                HStack(spacing: 4) {
                    Image(systemName: alarmManager.notificationAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    Text(alarmManager.notificationAuthorized ? "Thông báo: Bật" : "Cần cấp quyền")
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(alarmManager.notificationAuthorized ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(alarmManager.notificationAuthorized ? .green : .orange)
                .cornerRadius(8)
                .onTapGesture {
                    if !alarmManager.notificationAuthorized {
                        alarmManager.requestNotificationPermission()
                    }
                }
                
                // Background Audio Badge
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text(alarmManager.backgroundKeepAliveEnabled ? "Chạy ngầm: Bật" : "Chạy ngầm: Tắt")
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Active Countdown Card
    private var activeCountdownCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("BÁO THỨC ĐANG ĐẾM NGƯỢC")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.orange)
                    
                    if let target = alarmManager.targetAlarmDate {
                        Text("Sẽ reo lúc: \(formattedClock(target))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                Button(action: {
                    alarmManager.cancelAlarm()
                }) {
                    Text("Huỷ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            Text(formattedRemaining(alarmManager.remainingSeconds))
                .font(.system(size: 40, weight: .black, design: .monospaced))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
            
            Text("💡 Gợi ý: Hãy khoá màn hình (Lock Phone) ngay bây giờ để kiểm tra khả năng thức tỉnh của ứng dụng.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.5), lineWidth: 2)
        )
        .cornerRadius(16)
    }
    
    // MARK: - Quick Test Card
    private var quickTestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kiểm tra nhanh (Quick Countdown)", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Chọn khoảng thời gian ngắn để test chuông và phản hồi chạy ngầm:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                quickTestButton(title: "5 Giây", seconds: 5, color: .blue)
                quickTestButton(title: "15 Giây", seconds: 15, color: .indigo)
                quickTestButton(title: "30 Giây", seconds: 30, color: .purple)
                quickTestButton(title: "1 Phút", seconds: 60, color: .teal)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func quickTestButton(title: String, seconds: Int, color: Color) -> some View {
        Button(action: {
            alarmManager.startQuickCountdown(seconds: seconds)
        }) {
            HStack {
                Image(systemName: "stopwatch.fill")
                Text(title)
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Custom Alarm Card
    private var customAlarmCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Đặt giờ báo thức cụ thể", systemImage: "clock.badge.checkmark.fill")
                .font(.headline)
            
            DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 120)
                .clipped()
            
            Button(action: {
                alarmManager.setSpecificAlarm(date: selectedDate)
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Kích hoạt Báo Thức Giờ Này")
                        .fontWeight(.bold)
                }
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Settings & Keep-Alive
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cấu hình Sideload Chạy Ngầm", systemImage: "gearshape.fill")
                .font(.headline)
            
            Toggle(isOn: $alarmManager.backgroundKeepAliveEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Silent Audio Keep-Alive")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Phát âm thanh tĩnh siêu nhỏ để iOS không tắt app khi khoá màn hình")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Button(action: {
                alarmManager.triggerAlarm()
            }) {
                HStack {
                    Image(systemName: "speaker.wave.3")
                    Text("Bật thử chuông báo ngay (Test Loa & Mute)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Logs Console Card
    private var logsConsoleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Nhật ký trạng thái (Live Logs)", systemImage: "terminal.fill")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = logger.exportText()
                    withAnimation {
                        showingCopiedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingCopiedToast = false
                        }
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    logger.clear()
                }) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if logger.entries.isEmpty {
                        Text("Chưa có sự kiện nào...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(logger.entries.reversed()) { entry in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: entry.level.icon)
                                    .font(.caption2)
                                    .foregroundColor(entry.level.color)
                                    .padding(.top, 2)
                                
                                Text("[\(entry.formattedTime)]")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(entry.message)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            .padding(10)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    private func formattedClock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formattedRemaining(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Fullscreen Ringing View
struct AlarmRingingView: View {
    @ObservedObject var alarmManager = AlarmManager.shared
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 220, height: 220)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.9)
                    
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.white)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
                
                VStack(spacing: 8) {
                    Text("BÁO THỨC ĐANG REO!")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Chuông báo thử nghiệm đang phát hết âm lượng")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        alarmManager.dismissAlarm()
                    }) {
                        Text("DỪNG BÁO THỨC")
                            .font(.headline)
                            .fontWeight(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        alarmManager.snoozeAlarm(seconds: 30)
                    }) {
                        Text("Báo lại sau 30 giây (Snooze)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }
}
