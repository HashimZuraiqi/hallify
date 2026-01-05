import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/hall_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class HallProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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
    _firestoreService.getAllHalls().listen((halls) {
      _halls = halls;
      notifyListeners();
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

  /// Delete a hall
  Future<bool> deleteHall(String hallId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete all images
      await _storageService.deleteHallImages(hallId);

      // Delete hall from Firestore
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

  /// Overloaded createHall method that accepts HallModel and image paths
  Future<String?> createHall(HallModel hall, {List<String>? imagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create hall first to get ID
      final hallId = await _firestoreService.createHall(hall);

      // Upload images if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final imageFiles = imagePaths.map((path) => File(path)).toList();
        final imageUrls = await _storageService.uploadHallImages(
          imageFiles: imageFiles,
          hallId: hallId,
        );

        // Update hall with image URLs
        final updatedHall = hall.copyWith(id: hallId, imageUrls: imageUrls);
        await _firestoreService.updateHall(updatedHall);
      }

      _isLoading = false;
      notifyListeners();
      return hallId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Overloaded updateHall method that accepts HallModel and new image paths
  Future<bool> updateHall(HallModel hall, {List<String>? newImagePaths}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> updatedImageUrls = List.from(hall.imageUrls);

      // Upload new images if provided
      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        final imageFiles = newImagePaths.map((path) => File(path)).toList();
        final newImageUrls = await _storageService.uploadHallImages(
          imageFiles: imageFiles,
          hallId: hall.id,
        );
        updatedImageUrls.addAll(newImageUrls);
      }

      // Update hall
      final updatedHall = hall.copyWith(
        imageUrls: updatedImageUrls,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateHall(updatedHall);

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
