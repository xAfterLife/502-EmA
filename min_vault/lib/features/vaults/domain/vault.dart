import 'package:equatable/equatable.dart';

class Vault extends Equatable {
  final String name;
  final String folderName;
  final int itemCount;

  const Vault({
    required this.name,
    required this.folderName,
    required this.itemCount,
  });

  Vault copyWith({
    String? id,
    String? name,
    String? folderName,
    int? itemCount,
  }) => Vault(
    name: name ?? this.name,
    folderName: folderName ?? this.folderName,
    itemCount: itemCount ?? this.itemCount,
  );

  @override
  List<Object?> get props => [name, folderName, itemCount];
}
