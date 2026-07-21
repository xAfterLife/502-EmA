import 'package:equatable/equatable.dart';

enum ItemType { password, note, file, image }

class VaultItem extends Equatable {
  const VaultItem({
    required this.id,
    required this.title,
    required this.type,
    required this.hasThumbnail,
    required this.createdAt,
  });

  final String id;
  final String title;
  final ItemType type;
  final bool hasThumbnail;
  final DateTime createdAt;

  VaultItem copyWith({
    String? id,
    String? title,
    ItemType? type,
    bool? hasThumbnail,
    DateTime? createdAt,
  }) => VaultItem(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    hasThumbnail: hasThumbnail ?? this.hasThumbnail,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, title, type, hasThumbnail, createdAt];
}
