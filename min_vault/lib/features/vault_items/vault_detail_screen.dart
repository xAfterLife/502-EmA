import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/core/di/injection.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vault_items/vault_item.dart';
import 'package:min_vault/features/vault_items/vault_item_repository.dart';
import 'package:min_vault/features/vault_items/vault_items_cubit.dart';
import 'package:min_vault/features/vault_items/vault_items_state.dart';

class VaultDetailScreenWrapper extends StatelessWidget {
  const VaultDetailScreenWrapper({required this.vault, super.key});

  final Vault vault;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultItemsCubit(
        repository: VaultItemRepository(
          folderName: vault.folderName,
          encryptionService: getIt<EncryptionService>(),
        ),
      ),
      child: VaultDetailScreen(vault: vault),
    );
  }
}

class VaultDetailScreen extends StatefulWidget {
  const VaultDetailScreen({required this.vault, super.key});

  final Vault vault;

  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VaultItemsCubit>().loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(title: Text(widget.vault.name)),
      body: SafeArea(
        child: BlocBuilder<VaultItemsCubit, VaultItemsState>(
          builder: (context, state) => switch (state) {
            ItemsInitial() => const SizedBox.shrink(),
            ItemsLoading() => const Center(child: CircularProgressIndicator()),
            ItemsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spM),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.dangerColor),
                ),
              ),
            ),
            ItemsLoaded(:final items, :final thumbnails) =>
              items.isEmpty
                  ? const _EmptyState()
                  : _ItemList(items: items, thumbnails: thumbnails),
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: AppTheme.onAccentColor,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final cubit = context.read<VaultItemsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (_) => _AddItemSheet(
        onSubmit: ({required title, required type, required value}) =>
            cubit.addItem(title: title, type: type, value: value),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.thumbnails});

  final List<VaultItem> items;
  final Map<String, Uint8List> thumbnails;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spM,
        AppTheme.spM,
        AppTheme.spM,
        AppTheme.spXXL + AppTheme.spL,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemTile(item: item, thumbnail: thumbnails[item.id]);
      },
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({required this.item, required this.thumbnail});

  final VaultItem item;
  final Uint8List? thumbnail;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  File? _tempFile;

  @override
  void dispose() {
    final tempFile = _tempFile;
    if (tempFile != null && tempFile.existsSync()) {
      tempFile.deleteSync();
    }
    super.dispose();
  }

  IconData get _typeIcon => switch (widget.item.type) {
    ItemType.password => Icons.key_outlined,
    ItemType.note => Icons.notes_outlined,
    ItemType.image => Icons.image_outlined,
    ItemType.file => Icons.insert_drive_file_outlined,
  };

  Future<void> _onTap(BuildContext context) async {
    final cubit = context.read<VaultItemsCubit>();
    switch (widget.item.type) {
      case ItemType.password:
      case ItemType.note:
        final value = await cubit.revealText(widget.item.id);
        if (context.mounted) _showRevealSheet(context, value);
        break;
      case ItemType.image:
        final file = await cubit.revealFile(widget.item.id);
        _tempFile = file;
        if (context.mounted) {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => _ImageViewer(file: file)));
        }
        break;
      case ItemType.file:
        // Support for generic type files not yet added
        break;
    }
  }

  void _showRevealSheet(BuildContext context, String value) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (_) => _RevealSheet(title: widget.item.title, value: value),
    );
  }

  void _confirmDelete(BuildContext context) {
    final cubit = context.read<VaultItemsCubit>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${widget.item.title}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textPrimaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.deleteItem(widget.item.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFileType = widget.item.type == ItemType.file;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: InkWell(
        onTap: isFileType ? null : () => _onTap(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spM),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: widget.thumbnail != null
                    ? Image.memory(
                        widget.thumbnail!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.accentLightColor,
                        child: Icon(_typeIcon, color: AppTheme.accentColor),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.item.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isFileType
                        ? AppTheme.textSecondaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (isFileType)
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spS),
                  child: Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: InteractiveViewer(child: Image.file(file))),
    );
  }
}

class _RevealSheet extends StatelessWidget {
  const _RevealSheet({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              constraints: BoxConstraints(maxHeight: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColour,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: SelectableText(
                value,
                style: TextStyle(color: AppTheme.textPrimaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copy(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.onAccentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
              ),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first item.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.onSubmit});

  final Future<void> Function({
    required String title,
    required ItemType type,
    required Object value,
  })
  onSubmit;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  ItemType? _selectedType;
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSaving = false;
  String? _error;

  bool get _isTextType =>
      _selectedType == ItemType.password || _selectedType == ItemType.note;

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _selectType(ItemType type) {
    setState(() {
      _selectedType = type;
      _error = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.single);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title cannot be empty.');
      return;
    }

    final Object value;
    if (_isTextType) {
      if (_valueController.text.isEmpty) {
        setState(() => _error = 'Value cannot be empty.');
        return;
      }
      value = _valueController.text;
    } else {
      final path = _pickedFile?.path;
      if (path == null) {
        setState(() => _error = 'Choose an image first.');
        return;
      }
      value = File(path);
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(title: title, type: _selectedType!, value: value);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spM,
        AppTheme.spL,
        AppTheme.spM,
        AppTheme.spM + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_selectedType != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: () => setState(() {
                      _selectedType = null;
                      _error = null;
                    }),
                    icon: const Icon(Icons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              Text(
                _selectedType == null ? 'Add Item' : _titleFor(_selectedType!),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _selectedType == null
              ? _TypePicker(onSelected: _selectType)
              : _buildForm(),
        ],
      ),
    );
  }

  String _titleFor(ItemType type) => switch (type) {
    ItemType.password => 'New Password',
    ItemType.note => 'New Note',
    ItemType.image => 'New Image',
    ItemType.file => 'New File',
  };

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          maxLength: 100,
          controller: _titleController,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimaryColor),
          decoration: const InputDecoration(
            hintText: 'Title',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        const SizedBox(height: 12),
        if (_isTextType)
          TextField(
            controller: _valueController,
            obscureText: _selectedType == ItemType.password,
            maxLines: _selectedType == ItemType.note ? 4 : 1,
            style: TextStyle(color: AppTheme.textPrimaryColor),
            decoration: InputDecoration(
              hintText: _selectedType == ItemType.password
                  ? 'Password'
                  : 'Note',
              prefixIcon: Icon(
                _selectedType == ItemType.password
                    ? Icons.key_outlined
                    : Icons.notes_outlined,
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined, color: AppTheme.accentColor),
            label: Text(
              _pickedFile?.name ?? 'Choose Image',
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppTheme.dangerColor)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.onAccentColor,
              disabledBackgroundColor: AppTheme.accentColor.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onAccentColor,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.onSelected});

  final ValueChanged<ItemType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _TypeOption(
          icon: Icons.key_outlined,
          label: 'Password',
          onTap: () => onSelected(ItemType.password),
        ),
        _TypeOption(
          icon: Icons.notes_outlined,
          label: 'Note',
          onTap: () => onSelected(ItemType.note),
        ),
        _TypeOption(
          icon: Icons.image_outlined,
          label: 'Image',
          onTap: () => onSelected(ItemType.image),
        ),
        const _TypeOption(
          icon: Icons.insert_drive_file_outlined,
          label: 'File',
          enabled: false,
          disabledLabel: 'Coming soon',
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.disabledLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? AppTheme.accentLightColor : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled
                  ? AppTheme.accentColor
                  : AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
            if (disabledLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                disabledLabel!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
