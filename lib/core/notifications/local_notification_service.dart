import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification tap
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Fallback with launcher icon if custom icon fails
      try {
        const fallbackSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        await _notificationsPlugin.initialize(
          const InitializationSettings(android: fallbackSettings),
        );
        _isInitialized = true;
      } catch (_) {}
    }
  }

  /// Request runtime notification permissions on Android 13+
  static Future<bool> requestPermissions() async {
    await init();
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Schedule upcoming occasion reminder (e.g. 1 day or 2 hours before)
  static Future<void> scheduleOccasionReminder({
    required int occasionId,
    required String occasionName,
    required String location,
    required DateTime reminderTime,
  }) async {
    if (reminderTime.isBefore(DateTime.now())) return;
    await init();

    try {
      final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'etole_occasion_channel',
        'Occasion Reminders',
        channelDescription:
            'Notifications for upcoming events, shoots and meetings',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );

      await _notificationsPlugin.zonedSchedule(
        occasionId + 200000,
        'Upcoming Occasion: $occasionName',
        location.isNotEmpty
            ? 'Location: $location'
            : 'Scheduled at ${reminderTime.toString()}',
        tzDateTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'occasion_$occasionId',
      );
    } catch (_) {}
  }

  static Future<void> cancelOccasionNotification(int occasionId) async {
    try {
      await _notificationsPlugin.cancel(occasionId + 200000);
    } catch (_) {}
  }

  /// Schedule task reminder for network locations or specific people
  static Future<void> scheduleNetworkTaskReminder({
    required int taskId,
    required String title,
    required String subtitle,
    required DateTime reminderTime,
  }) async {
    if (reminderTime.isBefore(DateTime.now())) return;
    await init();
    try {
      final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);
      const androidDetails = AndroidNotificationDetails(
        'etole_task_channel',
        'Tasks & Follow-ups',
        channelDescription: 'Reminders for client follow-ups and promises',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );
      await _notificationsPlugin.zonedSchedule(
        (taskId % 100000) + 300000,
        title,
        subtitle,
        tzDateTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_$taskId',
      );
    } catch (_) {}
  }

  static Future<void> cancelNetworkTaskReminder(int taskId) async {
    try {
      await _notificationsPlugin.cancel((taskId % 100000) + 300000);
    } catch (_) {}
  }

  /// Show ongoing notification while recording meeting
  static Future<void> showRecordingNotification({
    required String meetingTitle,
  }) async {
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'etole_recording_channel',
        'Meeting Recording',
        channelDescription: 'Active meeting recording session',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: 'ic_notification',
      );

      await _notificationsPlugin.show(
        9901,
        'Etole Recording Active',
        'Recording "$meetingTitle" · Screen can be locked safely',
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {
      // Quiet fail: never interrupt recording if notification fails
    }
  }

  static Future<void> hideRecordingNotification() async {
    try {
      await _notificationsPlugin.cancel(9901);
    } catch (_) {}
  }

  /// Show ongoing notification while transcribing
  static Future<void> showTranscriptionNotification({
    required String meetingTitle,
    required String status,
  }) async {
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'etole_transcription_channel',
        'Meeting Transcription',
        channelDescription: 'On-device speech transcription progress',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: 'ic_notification',
      );

      await _notificationsPlugin.show(
        9902,
        'Transcribing: $meetingTitle',
        status,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  static Future<void> hideTranscriptionNotification() async {
    try {
      await _notificationsPlugin.cancel(9902);
    } catch (_) {}
  }

  /// General Automation Alert Channel
  static const AndroidNotificationDetails _automationDetails =
      AndroidNotificationDetails(
        'etole_automation_channel',
        'Executive Automations',
        channelDescription: 'Watchdog alerts for overdue invoices, stale deals, VIP contacts & shoots',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );

  /// Show instant automation alert
  static Future<void> showAutomationAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: _automationDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  /// 1. Overdue Invoice Watchdog Notification
  static Future<void> showOverdueInvoiceAlert({
    required int docId,
    required String clientName,
    required String docNumber,
    required String amountStr,
  }) async {
    await showAutomationAlert(
      id: 300000 + docId,
      title: '🚨 Overdue Invoice: $docNumber',
      body:
          '$clientName has an overdue balance of $amountStr. Tap to chase via WhatsApp.',
      payload: 'overdue_invoice_$docId',
    );
  }

  /// 2. Milestone / Deposit Due Tomorrow
  static Future<void> showMilestoneDueAlert({
    required int docId,
    required String clientName,
    required String docNumber,
    required String amountStr,
  }) async {
    await showAutomationAlert(
      id: 310000 + docId,
      title: '📅 Milestone Due Tomorrow: $docNumber',
      body: 'Milestone payment ($amountStr) for $clientName is due tomorrow.',
      payload: 'milestone_due_$docId',
    );
  }

  /// 3. Stale Deal Follow-Up Radar
  static Future<void> showStaleDealAlert({
    required int leadId,
    required String leadName,
    required String company,
    required int daysStale,
  }) async {
    final companyText = company.isNotEmpty ? ' ($company)' : '';
    await showAutomationAlert(
      id: 320000 + leadId,
      title: '💼 Pitch Follow-Up Due: $leadName$companyText',
      body:
          'Pitched $daysStale days ago without recent response. Send a polite touchpoint note.',
      payload: 'stale_deal_$leadId',
    );
  }

  /// 4. VIP Contact Reconnect Timer
  static Future<void> showVipTouchpointAlert({
    required int contactId,
    required String contactName,
    required int daysInactive,
  }) async {
    await showAutomationAlert(
      id: 330000 + contactId,
      title: '🤝 VIP Touchpoint: $contactName',
      body:
          'No recorded touchpoint in $daysInactive days. Drop a friendly message or check-in.',
      payload: 'vip_touchpoint_$contactId',
    );
  }

  /// 5. T-24h Shoot & Call Sheet Checker
  static Future<void> showShootAlert({
    required int occasionId,
    required String occasionName,
    required String message,
  }) async {
    await showAutomationAlert(
      id: 340000 + occasionId,
      title: '🎬 Shoot Tomorrow: $occasionName',
      body: message,
      payload: 'shoot_checker_$occasionId',
    );
  }

  /// 6. Wrap Day Gear Reconciliation
  static Future<void> showGearReconciliationAlert({
    required int occasionId,
    required String occasionName,
  }) async {
    await showAutomationAlert(
      id: 350000 + occasionId,
      title: '📦 Shoot Wrapped: Reconcile Gear',
      body:
          '$occasionName has wrapped. Check in all cameras, lighting, and rented equipment.',
      payload: 'gear_reconcile_$occasionId',
    );
  }

  /// 7. Monthly Tax & Profit Rollup
  static Future<void> showMonthlyTaxRollupAlert({
    required String monthName,
    required String revenueStr,
    required String whtStr,
    required String vatStr,
  }) async {
    await showAutomationAlert(
      id: 360001,
      title: '📊 $monthName Tax & Cashflow Rollup',
      body:
          'Gross Invoiced: $revenueStr · WHT Reserve: $whtStr · VAT Reserve: $vatStr.',
      payload: 'monthly_tax_rollup',
    );
  }

  /// 8. Scheduled Backup Complete
  static Future<void> showBackupCompleteAlert({
    required String filename,
    required String sizeStr,
  }) async {
    await showAutomationAlert(
      id: 370001,
      title: '🔒 Offline Vault Auto-Backup Saved',
      body: 'Encrypted database snapshot saved ($sizeStr). Zero cloud leaks.',
      payload: 'auto_backup',
    );
  }

  /// 9. Post-Meeting Action Item Alarm
  static Future<void> schedulePostMeetingFollowUp({
    required int meetingId,
    required String meetingTitle,
    required DateTime followUpTime,
  }) async {
    if (followUpTime.isBefore(DateTime.now())) return;
    await init();
    try {
      final tzDateTime = tz.TZDateTime.from(followUpTime, tz.local);
      await _notificationsPlugin.zonedSchedule(
        meetingId + 380000,
        '📝 Meeting Concluded: $meetingTitle',
        'Log key decisions, action items, or draft a commercial proposal.',
        tzDateTime,
        const NotificationDetails(android: _automationDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'post_meeting_$meetingId',
      );
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
