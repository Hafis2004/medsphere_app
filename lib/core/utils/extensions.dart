import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String formatDate() => DateFormat('MMM dd, yyyy').format(this);

  String formatTime() => DateFormat('hh:mm a').format(this);
}
