import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';

class MenuFormDialog extends StatefulWidget {
  final MenuItem? menuItem;

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

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  String? _existingImageUrl;

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
    _existingImageUrl = item?.imageUrl;
    if (_selectedCategory != null &&
        !_categories.contains(_selectedCategory)) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSourceTile(
                icon: Icons.photo_camera_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Kamera',
                subtitle: 'Ambil foto baru dengan kamera',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _buildSourceTile(
                icon: Icons.photo_library_rounded,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                title: 'Galeri',
                subtitle: 'Pilih foto dari galeri',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImage != null || _existingImageUrl != null) ...[
                const SizedBox(height: 8),
                _buildSourceTile(
                  icon: Icons.delete_outline_rounded,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Hapus Foto',
                  subtitle: 'Hapus foto yang dipilih',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _existingImageUrl = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    if (parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harga harus berupa angka lebih besar dari 0')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final menuProvider = context.read<MenuProvider>();
    bool success = false;

    String? imageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      imageUrl = _pickedImage!.path;
    }

    if (widget.menuItem == null) {
      success = await menuProvider.addMenu(
        name: _nameController.text.trim(),
        price: parsedPrice,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );
    } else {
      success = await menuProvider.updateMenu(
        id: widget.menuItem!.id,
        name: _nameController.text.trim(),
        price: parsedPrice,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final err = menuProvider.errorMessage ?? 'Gagal menyimpan menu.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header dialog
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_rounded
                              : Icons.add_circle_outline_rounded,
                          color: const Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Menu' : 'Tambah Menu Baru',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Perbarui informasi produk menu'
                                  : 'Isi data produk yang akan dijual',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Color(0xFF64748B)),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),

                // Form body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== FOTO PRODUK =====
                        const Text(
                          'Foto Produk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isSubmitting
                              ? null
                              : _showImageSourceDialog,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _pickedImage != null ||
                                        _existingImageUrl != null
                                    ? const Color(0xFF2563EB)
                                        .withValues(alpha: 0.5)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: _buildImagePreview(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nama Menu
                        _buildFieldLabel('Nama Menu', required: true),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Nasi Goreng Spesial',
                            prefixIcon: Icon(
                              Icons.fastfood_rounded,
                              size: 20,
                              color: Color(0xFF94A3B8),
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

                        // Row: Harga + Kategori
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Harga',
                                      required: true),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType:
                                        TextInputType.number,
                                    enabled: !_isSubmitting,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly
                                    ],
                                    decoration:
                                        const InputDecoration(
                                      hintText: '25000',
                                      prefixText: 'Rp ',
                                      prefixStyle: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Harga wajib diisi';
                                      }
                                      final val =
                                          int.tryParse(value.trim());
                                      if (val == null || val <= 0) {
                                        return 'Harga harus > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Kategori'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    decoration:
                                        const InputDecoration(
                                      hintText: 'Pilih kategori',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Tanpa kategori'),
                                      ),
                                      ..._categories.map(
                                        (cat) =>
                                            DropdownMenuItem<String>(
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        _buildFieldLabel('Deskripsi'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            hintText:
                                'Keterangan porsi, bahan, atau rasa...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tombol
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.of(context)
                                        .pop(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  side: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed:
                                    _isSubmitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(isEditing
                                        ? 'Simpan Perubahan'
                                        : 'Tambah Menu'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              File(_pickedImage!.path),
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => setState(() => _pickedImage = null),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Ganti Foto',
                      style:
                          TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              _existingImageUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildUploadPlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => setState(() => _existingImageUrl = null),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Ganti Foto',
                      style:
                          TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildUploadPlaceholder();
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 28,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap untuk menambahkan foto',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'JPG, PNG • Maks. 800×800px',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2563EB)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Pilih Foto',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }
}
