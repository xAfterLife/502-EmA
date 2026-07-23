import 'package:equatable/equatable.dart';

enum ItemType { password, note, file, image }

/// Common image file extensions.
const imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.tiff',
  '.tif',
  '.ico',
  '.avif',
  '.heic',
  '.heif',
};

///TODO: find a better way to do this
bool isImageFile(String fileName) {
  final name = fileName.trim().toLowerCase();
  if (name.isEmpty) return false;

  final dotIndex = name.lastIndexOf('.');
  if (dotIndex > 0 && dotIndex < name.length - 1) {
    final ext = name.substring(dotIndex);
    return imageExtensions.contains(ext);
  }
  return false;
}

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
