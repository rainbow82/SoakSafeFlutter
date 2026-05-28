import BackgroundTasks
import UIKit

/// Switches the launcher icon based on how long the app has been idle.
/// Happy: < 7 days · Sad: 7–13 days · Storm: 14+ days since last foreground use.
final class AppIconManager {
  static let shared = AppIconManager()

  static let daysSad = 7
  static let daysStorm = 14
  static let bgTaskIdentifier = "com.shannonbeach.soaksafe.iconrefresh"

  private let lastForegroundKey = "last_foreground_ms"

  private init() {}

  enum Variant {
    case happy
    case sad
    case storm

    var alternateIconName: String? {
      switch self {
      case .happy: return nil
      case .sad: return "Sad"
      case .storm: return "Storm"
      }
    }
  }

  func onAppForeground() {
    saveLastForegroundMs(currentTimeMs())
    apply(.happy)
  }

  func refreshIconFromIdleTime() {
    apply(variantForIdleTime())
  }

  func registerBackgroundRefresh() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.bgTaskIdentifier,
      using: nil
    ) { task in
      self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
    }
  }

  func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      NSLog("AppIconManager: could not schedule refresh: \(error.localizedDescription)")
    }
  }

  private func handleBackgroundRefresh(task: BGAppRefreshTask) {
    scheduleBackgroundRefresh()
    task.expirationHandler = {}
    refreshIconFromIdleTime()
    task.setTaskCompleted(success: true)
  }

  private func variantForIdleTime() -> Variant {
    let lastMs = lastForegroundMs()
    if lastMs <= 0 {
      return .happy
    }
    let idleDays = Int((currentTimeMs() - lastMs) / (24 * 60 * 60 * 1000))
    if idleDays >= Self.daysStorm {
      return .storm
    }
    if idleDays >= Self.daysSad {
      return .sad
    }
    return .happy
  }

  private func apply(_ variant: Variant) {
    guard UIApplication.shared.supportsAlternateIcons else {
      return
    }
    let iconName = variant.alternateIconName
    guard UIApplication.shared.alternateIconName != iconName else {
      return
    }
    UIApplication.shared.setAlternateIconName(iconName) { error in
      if let error {
        NSLog("AppIconManager: icon swap failed: \(error.localizedDescription)")
      }
    }
  }

  private func currentTimeMs() -> Int64 {
    Int64(Date().timeIntervalSince1970 * 1000)
  }

  private func lastForegroundMs() -> Int64 {
    Int64(UserDefaults.standard.double(forKey: lastForegroundKey))
  }

  private func saveLastForegroundMs(_ whenMs: Int64) {
    UserDefaults.standard.set(Double(whenMs), forKey: lastForegroundKey)
  }
}
