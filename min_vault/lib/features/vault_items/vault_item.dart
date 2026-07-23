import 'package:equatable/equatable.dart';

enum ItemType { password, note, file, image }

class VaultItem extends Equatable {
  const VaultItem({
    required this.id,
    required this.title,
    required this.type,
    required this.hasThumbnail,
    required this.createdAt,
    this.fileName,
  });

  final String id;
  final String title;
  final ItemType type;
  final bool hasThumbnail;
  final DateTime createdAt;

  /// Original file name (with extension) for image/file items.
  final String? fileName;

  VaultItem copyWith({
    String? id,
    String? title,
    ItemType? type,
    bool? hasThumbnail,
    DateTime? createdAt,
    String? fileName,
  }) => VaultItem(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    hasThumbnail: hasThumbnail ?? this.hasThumbnail,
    createdAt: createdAt ?? this.createdAt,
    fileName: fileName ?? this.fileName,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    hasThumbnail,
    createdAt,
    fileName,
  ];
}
