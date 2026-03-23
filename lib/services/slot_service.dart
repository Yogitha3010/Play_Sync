class SlotService {
  static const String defaultOpeningTime = '06:00';
  static const String defaultClosingTime = '22:00';

  static List<String> generateSlots(String? openingTime, String? closingTime) {
    final startMinutes = _parseTimeToMinutes(
      openingTime ?? defaultOpeningTime,
    );
    final endMinutes = _parseTimeToMinutes(
      closingTime ?? defaultClosingTime,
    );

    if (startMinutes == null ||
        endMinutes == null ||
        endMinutes <= startMinutes) {
      return [];
    }

    final slots = <String>[];
    for (int start = startMinutes; start < endMinutes; start += 60) {
      final end = start + 60;
      if (end > endMinutes) {
        break;
      }
      slots.add('${_formatMinutes(start)} - ${_formatMinutes(end)}');
    }
    return slots;
  }

  static int? _parseTimeToMinutes(String value) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(value);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return (hour * 60) + minute;
  }

  static String formatDisplayTime(String time24) {
    final minutes = _parseTimeToMinutes(time24);
    if (minutes == null) {
      return time24;
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  static String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
