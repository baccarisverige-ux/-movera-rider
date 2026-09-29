/// The uppercased first letter of [name], or [whenEmpty] when [name] is
/// blank after trimming.
String initialFromName(String name, {String whenEmpty = ''}) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? whenEmpty : trimmed.substring(0, 1).toUpperCase();
}
