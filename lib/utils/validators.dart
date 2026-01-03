/// Validation utilities for form inputs

class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Regular expression for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must not exceed 50 characters';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if contains only digits and optional + at start
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate hall name
  static String? validateHallName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hall name is required';
    }

    if (value.trim().length < 3) {
      return 'Hall name must be at least 3 characters';
    }

    if (value.trim().length > 100) {
      return 'Hall name must not exceed 100 characters';
    }

    return null;
  }

  /// Validate hall description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }

    if (value.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }

    return null;
  }

  /// Validate capacity
  static String? validateCapacity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Capacity is required';
    }

    final capacity = int.tryParse(value);
    if (capacity == null) {
      return 'Please enter a valid number';
    }

    if (capacity < 10) {
      return 'Capacity must be at least 10';
    }

    if (capacity > 10000) {
      return 'Capacity must not exceed 10,000';
    }

    return null;
  }

  /// Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 1000000) {
      return 'Price seems too high';
    }

    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }

    return null;
  }

  /// Validate city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }

    if (value.trim().length < 2) {
      return 'Please enter a valid city name';
    }

    return null;
  }

  /// Validate message
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }

    if (value.trim().length > 500) {
      return 'Message must not exceed 500 characters';
    }

    return null;
  }
}
