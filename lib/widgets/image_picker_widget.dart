import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<File> selectedImages;
  final List<String> existingImageUrls;
  final Function(List<File>) onImagesSelected;
  final Function(int)? onRemoveSelected;
  final Function(String)? onRemoveExisting;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.selectedImages,
    this.existingImageUrls = const [],
    required this.onImagesSelected,
    this.onRemoveSelected,
    this.onRemoveExisting,
    this.maxImages = 10,
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = selectedImages.length + existingImageUrls.length;
    final canAddMore = totalImages < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              '$totalImages / $maxImages',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Images Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Existing images
            ...existingImageUrls.asMap().entries.map((entry) {
              return _ImageTile(
                isNetwork: true,
                imageUrl: entry.value,
                onRemove: onRemoveExisting != null
                    ? () => onRemoveExisting!(entry.value)
                    : null,
              );
            }),
            // Selected images
            ...selectedImages.asMap().entries.map((entry) {
              return _ImageTile(
                isNetwork: false,
                imageFile: entry.value,
                onRemove: onRemoveSelected != null
                    ? () => onRemoveSelected!(entry.key)
                    : null,
              );
            }),
            // Add button
            if (canAddMore)
              _AddImageButton(
                onTap: () => _showImageSourceDialog(context),
              ),
          ],
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (pickedFile != null) {
      final newImages = List<File>.from(selectedImages)
        ..add(File(pickedFile.path));
      onImagesSelected(newImages);
    }
  }

  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final remainingSlots = maxImages - selectedImages.length - existingImageUrls.length;
    
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (pickedFiles.isNotEmpty) {
      final newImages = List<File>.from(selectedImages)
        ..addAll(
          pickedFiles
              .take(remainingSlots)
              .map((xFile) => File(xFile.path)),
        );
      onImagesSelected(newImages);
    }
  }
}

class _ImageTile extends StatelessWidget {
  final bool isNetwork;
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback? onRemove;

  const _ImageTile({
    required this.isNetwork,
    this.imageUrl,
    this.imageFile,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
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
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor,
            style: BorderStyle.solid,
            width: 2,
          ),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
