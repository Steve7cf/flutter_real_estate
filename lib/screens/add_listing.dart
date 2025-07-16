import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isPickingImage = false;
  String _selectedType = 'House';

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
    final now = DateTime.now();
    final newListing = {
      'id': now.microsecondsSinceEpoch.toString(),
      'title': _titleController.text.trim(),
      'price': _priceController.text.replaceAll(RegExp(r'^Tsh\s*'), '').trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'bedrooms': _bedroomsController.text.trim(),
      'bathrooms': _bathroomsController.text.trim(),
      'area': _areaController.text.trim(),
      'type': _selectedType,
      'url': '',
      'scraped_at': now.toIso8601String(),
      'images': [_selectedImage!.path],
    };
    final listings = prefs.getStringList('user_listings') ?? [];
    listings.add(jsonEncode(newListing));
    await prefs.setStringList('user_listings', listings);
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
        title: const Text('Add Listing'),
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
                  'Property Details',
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
                  items: const [
                    DropdownMenuItem(value: 'House', child: Text('House')),
                    DropdownMenuItem(
                      value: 'Apartment',
                      child: Text('Apartment'),
                    ),
                    DropdownMenuItem(value: 'Villa', child: Text('Villa')),
                    DropdownMenuItem(value: 'Plot', child: Text('Plot')),
                    DropdownMenuItem(value: 'Condo', child: Text('Condo')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
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
                      : const Text('Add Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
