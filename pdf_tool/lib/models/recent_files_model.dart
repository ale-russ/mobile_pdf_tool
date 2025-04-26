class RecentFile {
  final String path;
  final DateTime openedAt;

  RecentFile({required this.path, required this.openedAt});

  Map<String, dynamic> toJson() => {
    'path': path,
    'openedAt': openedAt.toIso8601String(),
  };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
    path: json['path'],
    openedAt: DateTime.parse(json['openedAt']),
  );
}
