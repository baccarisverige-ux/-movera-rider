String formatSek(int minor) => 'kr ${(minor / 100).round()}';

/// Formats a whole-kronor amount (not minor units/öre) as "kr X". Use
/// [formatSek] instead when the value is in minor units.
String formatKr(num amount) => 'kr ${amount.toStringAsFixed(0)}';
