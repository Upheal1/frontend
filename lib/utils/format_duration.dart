String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0m';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
