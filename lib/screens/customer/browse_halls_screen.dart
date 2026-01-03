import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../providers/hall_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/hall_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import 'hall_details_screen.dart';

class BrowseHallsScreen extends StatefulWidget {
  const BrowseHallsScreen({super.key});

  @override
  State<BrowseHallsScreen> createState() => _BrowseHallsScreenState();
}

class _BrowseHallsScreenState extends State<BrowseHallsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCity;
  HallType? _selectedType;
  RangeValues _priceRange = const RangeValues(0, 5000);
  RangeValues _capacityRange = const RangeValues(50, 1000);
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    hallProvider.setFilters(
      city: _selectedCity,
      type: _selectedType,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      minCapacity: _capacityRange.start.toInt(),
      maxCapacity: _capacityRange.end.toInt(),
    );
    hallProvider.searchHalls();
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedType = null;
      _priceRange = const RangeValues(0, 5000);
      _capacityRange = const RangeValues(50, 1000);
    });
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    hallProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Halls'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            icon: Badge(
              isLabelVisible: _hasActiveFilters(),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Search halls by name...',
              onChanged: (value) {
                // Implement search logic
                setState(() {});
              },
              onClear: () {
                setState(() {});
              },
            ),
          ),
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),
          // Active Filters Chips
          if (_hasActiveFilters())
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedCity != null)
                    _FilterChip(
                      label: _selectedCity!,
                      onRemove: () {
                        setState(() => _selectedCity = null);
                        _applyFilters();
                      },
                    ),
                  if (_selectedType != null)
                    _FilterChip(
                      label: _getTypeLabel(_selectedType!),
                      onRemove: () {
                        setState(() => _selectedType = null);
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          // Halls List
          Expanded(
            child: Consumer<HallProvider>(
              builder: (context, hallProvider, _) {
                final halls = hallProvider.searchResults.isNotEmpty
                    ? hallProvider.searchResults
                    : hallProvider.halls;

                // Filter by search query
                final filteredHalls = _searchController.text.isEmpty
                    ? halls
                    : halls
                        .where((hall) => hall.name
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();

                if (hallProvider.isLoading) {
                  return const LoadingWidget(message: 'Loading halls...');
                }

                if (filteredHalls.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Halls Found',
                    message: 'Try adjusting your search or filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredHalls.length,
                  itemBuilder: (context, index) {
                    final hall = filteredHalls[index];
                    return HallCard(
                      hall: hall,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HallDetailsScreen(hall: hall),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Cities')),
              ...AppConstants.cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }),
            ],
            onChanged: (value) {
              setState(() => _selectedCity = value);
            },
          ),
          const SizedBox(height: 16),
          // Type Dropdown
          DropdownButtonFormField<HallType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Hall Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Types')),
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
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 20),
          // Price Range
          Text(
            'Price Range: \$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}/hr',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '\$${_priceRange.start.toInt()}',
              '\$${_priceRange.end.toInt()}',
            ),
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),
          // Capacity Range
          Text(
            'Capacity: ${_capacityRange.start.toInt()} - ${_capacityRange.end.toInt()} guests',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          RangeSlider(
            values: _capacityRange,
            min: 10,
            max: 5000,
            divisions: 100,
            labels: RangeLabels(
              '${_capacityRange.start.toInt()}',
              '${_capacityRange.end.toInt()}',
            ),
            onChanged: (values) {
              setState(() => _capacityRange = values);
            },
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCity != null || _selectedType != null;
  }

  String _getTypeLabel(HallType type) {
    switch (type) {
      case HallType.wedding:
        return 'Wedding';
      case HallType.conference:
        return 'Conference';
      case HallType.both:
        return 'Multi-purpose';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onRemove,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        labelStyle: const TextStyle(color: AppTheme.primaryColor),
        deleteIconColor: AppTheme.primaryColor,
      ),
    );
  }
}
