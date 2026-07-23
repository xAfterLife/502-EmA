import 'package:equatable/equatable.dart';

class Vault extends Equatable {
  final String name;
  final String folderName;
  final int itemCount;
  final bool cloudEnabled;
  final DateTime? lastSyncedAt;

  const Vault({
    required this.name,
    required this.folderName,
    required this.itemCount,
    this.cloudEnabled = false,
    this.lastSyncedAt,
  });

  Vault copyWith({
    String? name,
    String? folderName,
    int? itemCount,
    bool? cloudEnabled,
    DateTime? lastSyncedAt,
  }) => Vault(
    name: name ?? this.name,
    folderName: folderName ?? this.folderName,
    itemCount: itemCount ?? this.itemCount,
    cloudEnabled: cloudEnabled ?? this.cloudEnabled,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  List<Object?> get props => [
    name,
    folderName,
    itemCount,
    cloudEnabled,
    lastSyncedAt,
  ];
}
