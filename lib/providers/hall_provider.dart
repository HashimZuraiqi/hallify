import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/hall_model.dart';
import '../services/firestore_service.dart';
import '../services/base64_image_service.dart';

class HallProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Base64ImageService _imageService = Base64ImageService();

  List<HallModel> _halls = [];
  List<HallModel> _myHalls = [];
  List<HallModel> _searchResults = [];
  List<HallModel> _featuredHalls = [];
  HallModel? _selectedHall;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter states
  String? _selectedCity;
  HallType? _selectedType;
  int? _minCapacity;
  int? _maxCapacity;
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<HallModel> get halls => _halls;
  List<HallModel> get myHalls => _myHalls;
  List<HallModel> get organizerHalls => _myHalls; // Alias for consistency
  List<HallModel> get searchResults => _searchResults;
  List<HallModel> get featuredHalls => _featuredHalls;
  HallModel? get selectedHall => _selectedHall;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCity => _selectedCity;
  HallType? get selectedType => _selectedType;

  /// Load all halls (for customers)
  void loadAllHalls() {
    print('🔍 Loading all halls from Firestore...');
    _firestoreService.getAllHalls().listen((halls) {
      print('✅ Received ${halls.length} halls from Firestore');
      for (var hall in halls) {
        print('   - Hall: ${hall.name} (ID: ${hall.id}, Available: ${hall.isAvailable})');
      }
      _halls = halls;
      notifyListeners();
    }, onError: (error) {
      print('❌ Error loading halls: $error');
    });
  }

  /// Load featured halls
  Future<void> loadFeaturedHalls() async {
    try {
      _featuredHalls = await _firestoreService.getFeaturedHalls();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get hall by ID
  Future<HallModel?> getHallById(String hallId) async {
    try {
      _selectedHall = await _firestoreService.getHallById(hallId);
      notifyListeners();
      return _selectedHall;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Set selected hall
  void setSelectedHall(HallModel hall) {
    _selectedHall = hall;
    notifyListeners();
  }

  /// Clear selected hall
  void clearSelectedHall() {
    _selectedHall = null;
    notifyListeners();
  }

  /// Delete a hall (no Storage deletion needed - images are Base64 in Firestore)
  Future<bool> deleteHall(String hallId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete hall from Firestore (images are embedded as Base64)
      await _firestoreService.deleteHall(hallId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle hall availability
  Future<bool> toggleHallAvailability(HallModel hall) async {
    try {
      final updatedHall = hall.copyWith(
        isAvailable: !hall.isAvailable,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateHall(updatedHall);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle hall active status (alias for toggleHallAvailability)
  Future<bool> toggleHallActive(String hallId, bool isActive) async {
    try {
      // Find hall in myHalls
      final hall = _myHalls.firstWhere((h) => h.id == hallId);
      final updatedHall = hall.copyWith(
        isAvailable: isActive,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateHall(updatedHall);

      // Update local list
      final index = _myHalls.indexWhere((h) => h.id == hallId);
      if (index != -1) {
        _myHalls[index] = updatedHall;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Create hall with Base64-encoded images (FREE - no Storage needed)
  Future<String?> createHall(HallModel hall, {List<String>? imagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> imageBase64List = [];
      
      // Encode images to Base64 if provided (non-blocking)
      if (imagePaths != null && imagePaths.isNotEmpty) {
        try {
          print('Encoding ${imagePaths.length} images to Base64...');
          final imageFiles = imagePaths.map((path) => File(path)).toList();
          imageBase64List = await _imageService.encodeImagesToBase64(imageFiles);
          print('Successfully encoded ${imageBase64List.length} images');
        } catch (e) {
          print('Warning: Failed to encode some images: $e');
          // Continue without images rather than failing completely
        }
      }

      // Create hall with Base64 images (or without if encoding failed)
      final hallWithImages = hall.copyWith(
        imageBase64: imageBase64List,
        isAvailable: true,  // CRITICAL: Always set to true so hall appears
      );
      
      print('Creating hall in Firestore with ${imageBase64List.length} images...');
      final hallId = await _firestoreService.createHall(hallWithImages);
      print('Hall created with ID: $hallId');
      
      // Update with correct ID
      final updatedHall = hallWithImages.copyWith(id: hallId);
      await _firestoreService.updateHall(updatedHall);
      print('Hall updated with ID');

      _isLoading = false;
      notifyListeners();
      
      // Refresh the halls list
      loadAllHalls();
      
      return hallId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update hall with new Base64-encoded images (FREE - no Storage needed)
  Future<bool> updateHall(HallModel hall, {List<String>? newImagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> updatedImageBase64 = List.from(hall.imageBase64);

      // Encode new images if provided
      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        print('Encoding ${newImagePaths.length} new images to Base64...');
        final imageFiles = newImagePaths.map((path) => File(path)).toList();
        final newImages = await _imageService.encodeImagesToBase64(imageFiles);
        updatedImageBase64.addAll(newImages);
        print('Added ${newImages.length} new images');
      }

      // Update hall
      final updatedHall = hall.copyWith(
        imageBase64: updatedImageBase64,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateHall(updatedHall);

      _isLoading = false;
      notifyListeners();
      
      // Refresh the halls list
      loadAllHalls();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load organizer halls (void return - updates provider state)
  Future<void> loadOrganizerHalls(String organizerId) async {
    _isLoading = true;
    _errorMessage = null;
    // Defer notification to avoid setState during build
    Future.microtask(() => notifyListeners());

    try {
      // Use the stream-based method that exists in FirestoreService
      _firestoreService.getHallsByOrganizer(organizerId).listen((halls) {
        _myHalls = halls;
        _isLoading = false;
        // Defer notification to avoid setState during build
        Future.microtask(() => notifyListeners());
      });
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      Future.microtask(() => notifyListeners());
    }
  }

  /// Search halls with filters
  Future<void> searchHalls() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _firestoreService.searchHalls(
        city: _selectedCity,
        type: _selectedType,
        minCapacity: _minCapacity,
        maxCapacity: _maxCapacity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Set filters
  void setFilters({
    String? city,
    HallType? type,
    int? minCapacity,
    int? maxCapacity,
    double? minPrice,
    double? maxPrice,
  }) {
    _selectedCity = city;
    _selectedType = type;
    _minCapacity = minCapacity;
    _maxCapacity = maxCapacity;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _selectedCity = null;
    _selectedType = null;
    _minCapacity = null;
    _maxCapacity = null;
    _minPrice = null;
    _maxPrice = null;
    _searchResults = [];
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
