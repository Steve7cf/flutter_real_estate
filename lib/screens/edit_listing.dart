import 'package:flutter/material.dart';
import 'package:real_estate/models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditListingScreen extends StatefulWidget {
  final Property property;
  const EditListingScreen({super.key, required this.property});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  static const List<String> allowedTypes = [
    'House',
    'Apartment',
    'Villa',
    'Plot',
    'Condo',
    'Other',
  ];
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _areaController;
  late String _selectedType;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleController = TextEditingController(text: p.title);
    _priceController = TextEditingController(text: p.price);
    _locationController = TextEditingController(text: p.location);
    _descriptionController = TextEditingController(text: p.description);
    _bedroomsController = TextEditingController(text: p.bedrooms);
    _bathroomsController = TextEditingController(text: p.bathrooms);
    _areaController = TextEditingController(text: p.area);
    _selectedType = allowedTypes.contains(p.type) ? p.type : 'Other';
    if (p.images.isNotEmpty &&
        (p.images.first.startsWith('/') ||
            p.images.first.startsWith('file://'))) {
      _selectedImage = File(p.images.first);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('user_listings') ?? [];
    final updatedListing = {
      'id': widget.property.id,
      'title': _titleController.text.trim(),
      'price': _priceController.text.replaceAll(RegExp(r'^Tsh\s*'), '').trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'bedrooms': _bedroomsController.text.trim(),
      'bathrooms': _bathroomsController.text.trim(),
      'area': _areaController.text.trim(),
      'type': _selectedType,
      'url': '',
      'scraped_at': widget.property.scrapedAt,
      'images': [_selectedImage!.path],
    };
    final idx = list.indexWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == widget.property.id;
    });
    if (idx >= 0) {
      list[idx] = jsonEncode(updatedListing);
      await prefs.setStringList('user_listings', list);
    }
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing updated!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: theme.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor.withAlpha(51)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Property Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isPickingImage ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _selectedImage != null
                            ? Container(
                                height: 180,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withAlpha(20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                height: 180,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withAlpha(20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: theme.primaryColor.withAlpha(
                                          179,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add image',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.primaryColor
                                                  .withAlpha(179),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        if (_isPickingImage)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black26,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    'Title',
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: _inputDecoration(
                    'Price (Tsh)',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Text(
                        'Tsh',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a price' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                    'Location',
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a location' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                    'Description',
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        decoration: _inputDecoration(
                          'Bedrooms',
                          prefixIcon: const Icon(Icons.king_bed_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter bedrooms' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        decoration: _inputDecoration(
                          'Bathrooms',
                          prefixIcon: const Icon(Icons.bathtub_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter bathrooms' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _areaController,
                  decoration: _inputDecoration(
                    'Area (e.g. 120 sqm)',
                    prefixIcon: const Icon(Icons.square_foot),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter area' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _inputDecoration(
                    'Type',
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: allowedTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? 'House';
                    });
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select type' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
