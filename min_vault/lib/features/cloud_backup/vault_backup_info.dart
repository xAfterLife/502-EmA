class VaultBackupInfo {
  const VaultBackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VaultBackupInfo.fromJson(Map<String, dynamic> json) {
    return VaultBackupInfo(
      id: json['vault_id'],
      name: json['vault_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
