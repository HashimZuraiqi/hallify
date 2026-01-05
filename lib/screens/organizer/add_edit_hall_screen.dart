import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hall_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/map_picker_widget.dart';
import '../../widgets/loading_widget.dart';

class AddEditHallScreen extends StatefulWidget {
  final HallModel? hall;

  const AddEditHallScreen({super.key, this.hall});

  @override
  State<AddEditHallScreen> createState() => _AddEditHallScreenState();
}

class _AddEditHallScreenState extends State<AddEditHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();

  HallType _selectedType = HallType.wedding;
  String? _selectedCity;
  List<String> _selectedFeatures = [];
  List<String> _imageUrls = [];
  List<String> _newImagePaths = [];
  double _latitude = 0;
  double _longitude = 0;
  bool _isSaving = false;

  bool get _isEditing => widget.hall != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadHallData();
    }
  }

  void _loadHallData() {
    final hall = widget.hall!;
    _nameController.text = hall.name;
    _descriptionController.text = hall.description;
    _addressController.text = hall.address;
    _capacityController.text = hall.capacity.toString();
    _priceController.text = hall.pricePerHour.toString();
    _selectedType = hall.type;
    _selectedCity = hall.city;
    _selectedFeatures = List.from(hall.features);
    _imageUrls = List.from(hall.imageUrls);
    _latitude = hall.latitude;
    _longitude = hall.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveHall() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      Helpers.showErrorSnackbar(context, 'Please select a city');
      return;
    }
    if (_imageUrls.isEmpty && _newImagePaths.isEmpty) {
      Helpers.showErrorSnackbar(context, 'Please add at least one image');
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hallProvider = Provider.of<HallProvider>(context, listen: false);

    try {
      final hall = HallModel(
        id: widget.hall?.id ?? '',
        organizerId: authProvider.user!.id,
        organizerName: authProvider.user!.name,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        address: _addressController.text.trim(),
        city: _selectedCity!,
        latitude: _latitude,
        longitude: _longitude,
        capacity: int.parse(_capacityController.text),
        pricePerHour: double.parse(_priceController.text),
        pricePerDay: double.parse(_priceController.text) * 8, // Default: 8 hours per day
        features: _selectedFeatures,
        imageUrls: _imageUrls,
        rating: widget.hall?.rating ?? 0,
        totalReviews: widget.hall?.totalReviews ?? 0,
        isAvailable: widget.hall?.isAvailable ?? true,
        createdAt: widget.hall?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await hallProvider.updateHall(
          hall,
          newImagePaths: _newImagePaths.isNotEmpty ? _newImagePaths : null,
        );
        if (!mounted) return;
        Helpers.showSuccessSnackbar(context, 'Hall updated successfully');
      } else {
        await hallProvider.createHall(
          hall,
          imagePaths: _newImagePaths,
        );
        if (!mounted) return;
        Helpers.showSuccessSnackbar(context, 'Hall created successfully');
      }

      Navigator.pop(context);
    } catch (e) {
      Helpers.showErrorSnackbar(
        context,
        _isEditing ? 'Failed to update hall' : 'Failed to create hall',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Hall' : 'Add Hall'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              _buildSectionTitle('Images'),
              const SizedBox(height: 12),
              _buildImagesSection(),
              const SizedBox(height: 24),
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _nameController,
                label: 'Hall Name',
                prefixIcon: Icons.business,
                validator: Validators.validateHallName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: Validators.validateDescription,
              ),
              const SizedBox(height: 16),
              // Hall Type
              DropdownButtonFormField<HallType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Hall Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: HallType.wedding,
                    child: Text('Wedding Hall'),
                  ),
                  DropdownMenuItem(
                    value: HallType.conference,
                    child: Text('Conference Hall'),
                  ),
                  DropdownMenuItem(
                    value: HallType.both,
                    child: Text('Multi-purpose'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 24),
              // Location Section
              _buildSectionTitle('Location'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _addressController,
                label: 'Full Address',
                prefixIcon: Icons.location_on,
                validator: Validators.validateAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: AppConstants.cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCity = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Map Picker
              _buildSectionTitle('Pin Location on Map (Optional)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MapPickerWidget(
                    initialLatitude: _latitude != 0 ? _latitude : null,
                    initialLongitude: _longitude != 0 ? _longitude : null,
                    onLocationSelected: (lat, lng, address) {
                      setState(() {
                        _latitude = lat;
                        _longitude = lng;
                        if (address != null && _addressController.text.isEmpty) {
                          _addressController.text = address;
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Capacity and Price
              _buildSectionTitle('Capacity & Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _capacityController,
                      label: 'Capacity',
                      prefixIcon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateCapacity,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price/Hour (\$)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Features
              _buildSectionTitle('Features & Amenities'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.hallFeatures.map((feature) {
                  final isSelected = _selectedFeatures.contains(feature);
                  return FilterChip(
                    label: Text(feature),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFeatures.add(feature);
                        } else {
                          _selectedFeatures.remove(feature);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: _isEditing ? 'Update Hall' : 'Create Hall',
                  onPressed: _saveHall,
                  isLoading: _isSaving,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildImagesSection() {
    final allImages = [..._imageUrls, ..._newImagePaths];

    return Column(
      children: [
        // Image Grid
        if (allImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length + 1,
              itemBuilder: (context, index) {
                if (index == allImages.length) {
                  return _AddImageButton(
                    onTap: () => _showImagePicker(),
                  );
                }

                final image = allImages[index];
                final isUrl = image.startsWith('http');

                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isUrl
                            ? CachedNetworkImage(
                                imageUrl: image,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ShimmerLoading(
                                  width: 120,
                                  height: 120,
                                ),
                              )
                            : Image.asset(
                                image,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isUrl) {
                                _imageUrls.remove(image);
                              } else {
                                _newImagePaths.remove(image);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: () => _showImagePicker(),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Add Images',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera picker
                setState(() {
                  _newImagePaths.add('assets/images/placeholder.png');
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery picker
                setState(() {
                  _newImagePaths.add('assets/images/placeholder.png');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Colors.grey[500]),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
