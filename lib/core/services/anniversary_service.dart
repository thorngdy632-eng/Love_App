import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/chat_repository.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';

class AnniversaryService {
  AnniversaryService._();

  static const int _monthlyNotificationId = 99902;
  static const int _yearlyNotificationId = 99903;
  static const String _channelId = 'anniversary_channel';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Call this when app starts and user is authenticated.
  static Future<void> checkAndNotify({required String myUid}) async {
    final now = DateTime.now();
    final start = AppConstants.relationshipStartDate;

    if (now.day != start.day) return;

    final totalMonths = (now.year - start.year) * 12 + (now.month - start.month);
    if (totalMonths <= 0) return;

    final isYearly = now.month == start.month && totalMonths >= 12;
    final message = _buildMessage(totalMonths: totalMonths, isYearly: isYearly);
    final title = _buildTitle(totalMonths: totalMonths, isYearly: isYearly);

    await NotificationService.showNotification(title: title, body: message);

    if (!await _alreadySentToday()) {
      await ChatRepository().sendTextMessage(
        senderId: 'system_anniversary',
        senderName: '💕 ${KhmerText.appName}',
        text: message,
      );
      await _markSentToday(message);
    }

    await _scheduleNext();
  }

  static String _buildTitle({required int totalMonths, required bool isYearly}) {
    if (isYearly) {
      final years = totalMonths ~/ 12;
      return '🎉 ខួប $years ឆ្នាំហើយ!';
    }
    return '💕 ខួប $totalMonths ខែហើយ!';
  }

  static String _buildMessage({required int totalMonths, required bool isYearly}) {
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    if (isYearly) {
      return '🎉 ខួបអាពាហ៍ពិពាហ៍លើកទី $years ឆ្នាំ! '
          'សូមអបអរសាទរដល់ពួកយើងទាំងពីរនាក់ '
          'សូមថ្ងៃនេះពោរពេញទៅដោយស្នេហា សុភមង្គល និងការចងចាំដ៏ស្រស់ស្អាត 💕';
    }
    if (years > 0) {
      return '💕 ខួប $years ឆ្នាំ $months ខែ! '
          'រាល់ថ្ងៃដែលយើងនៅជាមួយគ្នា គឺជាថ្ងៃដ៏មានតម្លៃបំផុតសម្រាប់ខ្ញុំ 💕';
    }
    return '💕 ខួប $months ខែ! ស្រលាញ់អ្នកកាន់តែខ្លាំងរាល់ថ្ងៃ 💕';
  }

  static Future<bool> _alreadySentToday() async {
    final doc = await FirebaseFirestore.instance
        .collection('system')
        .doc('anniversary_tracker')
        .get();
    if (!doc.exists) return false;
    final lastSent = (doc.data()?['lastSent'] as Timestamp?)?.toDate();
    if (lastSent == null) return false;
    final now = DateTime.now();
    return lastSent.year == now.year &&
        lastSent.month == now.month &&
        lastSent.day == now.day;
  }

  static Future<void> _markSentToday(String message) async {
    await FirebaseFirestore.instance
        .collection('system')
        .doc('anniversary_tracker')
        .set({
      'lastSent': FieldValue.serverTimestamp(),
      'lastMessage': message,
    });
  }

  static Future<void> _scheduleNext() async {
    if (kIsWeb) return;

    await _ensureChannelCreated();

    final now = DateTime.now();
    final start = AppConstants.relationshipStartDate;

    var nextDate = DateTime(now.year, now.month, start.day, 9, 0, 0);
    if (nextDate.isBefore(now) || nextDate.day == now.day) {
      nextDate = DateTime(now.year, now.month + 1, start.day, 9, 0, 0);
    }

    final location = tz.local;
    final tzDate = tz.TZDateTime.from(nextDate, location);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'ខួបរបស់យើង',
        channelDescription: 'ការជូនដំណឹងនៅថ្ងៃខួប',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      _monthlyNotificationId,
      '💕 ខួបរបស់យើង!',
      'បើកកម្មវិធីដើម្បីមើលសារភ្ញាក់ផ្អើល 🎉',
      tzDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> _ensureChannelCreated() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'ខួបរបស់យើង',
            description: 'ការជូនដំណឹងនៅថ្ងៃខួប',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  static Future<void> cancelScheduled() async {
    if (kIsWeb) return;
    await _plugin.cancel(_monthlyNotificationId);
    await _plugin.cancel(_yearlyNotificationId);
  }
}
