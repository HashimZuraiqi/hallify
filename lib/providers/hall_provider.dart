import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/hall_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class HallProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

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

  /// Load all halls (for customers) - paginated for performance
  void loadAllHalls({int limit = 10}) {
    print('🔍 Loading halls from Firestore (limit: $limit)...');
    _firestoreService.getAllHalls(limit: limit).listen((halls) {
      print('✅ Received ${halls.length} halls from Firestore');
      _halls = halls;
      notifyListeners();
    }, onError: (error) {
      print('❌ Error loading halls: $error');
    });
  }

  /// Load more halls (for pagination)
  void loadMoreHalls() {
    loadAllHalls(limit: _halls.length + 10);
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

  /// Create hall with Cloudinary image URLs (fast loading)
  Future<String?> createHall(HallModel hall, {List<String>? imagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> imageUrls = [];
      
      // Upload images to Cloudinary if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        try {
          print('Uploading ${imagePaths.length} images to Cloudinary...');
          final imageFiles = imagePaths.map((path) => File(path)).toList();
          
          // Generate a temporary ID for the folder
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          imageUrls = await _cloudinaryService.uploadHallImages(
            imageFiles: imageFiles,
            hallId: tempId,
          );
          print('Successfully uploaded ${imageUrls.length} images');
        } catch (e) {
          print('Warning: Failed to upload some images: $e');
          // Continue without images rather than failing completely
        }
      }

      // Create hall with image URLs
      final hallWithImages = hall.copyWith(
        imageUrls: imageUrls,
        imageBase64: [], // Clear any Base64 data
        isAvailable: true,
      );
      
      print('Creating hall in Firestore with ${imageUrls.length} image URLs...');
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
      print('Error creating hall: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update hall with new Cloudinary image URLs (fast loading)
  Future<bool> updateHall(HallModel hall, {List<String>? newImagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> updatedImageUrls = List.from(hall.imageUrls);

      // Upload new images if provided
      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        print('Uploading ${newImagePaths.length} new images to Cloudinary...');
        final imageFiles = newImagePaths.map((path) => File(path)).toList();
        final newUrls = await _cloudinaryService.uploadHallImages(
          imageFiles: imageFiles,
          hallId: hall.id,
        );
        updatedImageUrls.addAll(newUrls);
        print('Added ${newUrls.length} new image URLs');
      }

      // Update hall
      final updatedHall = hall.copyWith(
        imageUrls: updatedImageUrls,
        imageBase64: [], // Clear any old Base64 data
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

  /// Load organizer halls (void return - updates provider state) - paginated for performance
  Future<void> loadOrganizerHalls(String organizerId, {int limit = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    // Defer notification to avoid setState during build
    Future.microtask(() => notifyListeners());

    try {
      // Use the stream-based method that exists in FirestoreService
      _firestoreService.getHallsByOrganizer(organizerId, limit: limit).listen((halls) {
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
