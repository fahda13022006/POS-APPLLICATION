import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';

class MenuFormDialog extends StatefulWidget {
  final MenuItem? menuItem; // null = Tambah, ada nilai = Ubah

  const MenuFormDialog({super.key, this.menuItem});

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Makanan',
    'Minuman',
    'Camilan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toString() : '',
    );
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _selectedCategory = item?.category;
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    if (parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka lebih besar dari 0')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final menuProvider = context.read<MenuProvider>();
    bool success = false;

    if (widget.menuItem == null) {
      // Tambah Menu
      success = await menuProvider.addMenu(
        name: _nameController.text.trim(),
        price: parsedPrice,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } else {
      // Ubah Menu
      success = await menuProvider.updateMenu(
        id: widget.menuItem!.id,
        name: _nameController.text.trim(),
        price: parsedPrice,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final err = menuProvider.errorMessage ?? 'Gagal menyimpan menu.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.menuItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Dialog
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isEditing ? 'Ubah Menu' : 'Tambah Menu Baru',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nama Menu (Wajib)
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Nama Menu *',
                    hintText: 'Contoh: Nasi Goreng Spesial',
                    prefixIcon: const Icon(Icons.restaurant_menu),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama menu wajib diisi';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama menu minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Harga (Wajib, > 0)
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  enabled: !_isSubmitting,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Harga (Rupiah) *',
                    hintText: 'Contoh: 25000',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    final val = int.tryParse(value.trim());
                    if (val == null || val <= 0) {
                      return 'Harga harus berupa angka lebih besar dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Kategori (Opsional)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori (Opsional)',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Pilih Kategori'),
                    ),
                    ..._categories.map(
                      (cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      ),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Deskripsi (Opsional)
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Keterangan porsi, bahan, atau rasa...',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambah Menu',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
