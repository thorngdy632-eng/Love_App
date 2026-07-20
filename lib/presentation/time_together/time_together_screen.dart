import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/romantic_card.dart';

class TimeTogetherScreen extends StatefulWidget {
  const TimeTogetherScreen({super.key});

  @override
  State<TimeTogetherScreen> createState() => _TimeTogetherScreenState();
}

class _TimeTogetherScreenState extends State<TimeTogetherScreen> {
  Timer? _timer;
  _TimeParts _together = const _TimeParts(0, 0, 0);
  _TimeParts _countdown = const _TimeParts(0, 0, 0);
  DateTime _nextAnniversary = DateTime.now();

  @override
  void initState() {
    super.initState();
    _computeAll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _computeAll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _computeAll() {
    final start = AppConstants.relationshipStartDate;
    final now = DateTime.now();

    _together = _TimeParts.fromDuration(_calendarDifference(start, now));

    var nextAnniversary = DateTime(now.year, start.month, start.day);
    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(now.year + 1, start.month, start.day);
    }
    _nextAnniversary = nextAnniversary;
    _countdown = _TimeParts.fromDuration(_calendarDifference(now, nextAnniversary));

    if (mounted) setState(() {});
  }

  /// Computes an approximate calendar-aware years/months/days breakdown
  /// (used for both "time together" and "countdown to next anniversary").
  Duration _calendarDifference(DateTime from, DateTime to) {
    return to.difference(from);
  }

  _YMD _breakdown(DateTime from, DateTime to) {
    int years = to.year - from.year;
    int months = to.month - from.month;
    int days = to.day - from.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(to.year, to.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    return _YMD(years, months, days);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ymd = _breakdown(AppConstants.relationshipStartDate, now);
    final countdownYmd = _breakdown(now, _nextAnniversary);

    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.timeTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RomanticCard(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    '${KhmerText.timeSince} ${DateFormat('dd/MM/yyyy').format(AppConstants.relationshipStartDate)}',
                    style: const TextStyle(color: Colors.white, fontFamily: 'KantumruyPro', fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TimeUnit(value: ymd.years, label: KhmerText.timeYears),
                      _TimeUnit(value: ymd.months, label: KhmerText.timeMonths),
                      _TimeUnit(value: ymd.days, label: KhmerText.timeDays),
                      _TimeUnit(value: _together.hours, label: KhmerText.timeHours),
                      _TimeUnit(value: _together.minutes, label: KhmerText.timeMinutes),
                      _TimeUnit(value: _together.seconds, label: KhmerText.timeSeconds),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            RomanticCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cake, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        KhmerText.timeCountdown,
                        style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_nextAnniversary),
                    style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TimeUnit(value: countdownYmd.months, label: KhmerText.timeMonths, small: true),
                      _TimeUnit(value: countdownYmd.days, label: KhmerText.timeDays, small: true),
                      _TimeUnit(value: _countdown.hours, label: KhmerText.timeHours, small: true),
                      _TimeUnit(value: _countdown.minutes, label: KhmerText.timeMinutes, small: true),
                      _TimeUnit(value: _countdown.seconds, label: KhmerText.timeSeconds, small: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final bool small;

  const _TimeUnit({required this.value, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 60.0 : 68.0;
    return Container(
      width: size,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: small ? AppColors.background : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontFamily: 'KantumruyPro',
              fontSize: small ? 18 : 22,
              color: small ? AppColors.primaryDark : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'KantumruyPro',
              fontSize: 11,
              color: small ? AppColors.textLight : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _YMD {
  final int years;
  final int months;
  final int days;
  _YMD(this.years, this.months, this.days);
}

class _TimeParts {
  final int hours;
  final int minutes;
  final int seconds;
  const _TimeParts(this.hours, this.minutes, this.seconds);

  factory _TimeParts.fromDuration(Duration d) {
    return _TimeParts(d.inHours % 24, d.inMinutes % 60, d.inSeconds % 60);
  }
}
