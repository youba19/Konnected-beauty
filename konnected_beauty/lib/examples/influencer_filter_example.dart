import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/bloc/influencers/influencers_bloc.dart';
import '../core/utils/filter_utils.dart';
import '../core/models/filter_model.dart';

/// Example usage of the Influencers filter functionality
class InfluencerFilterExample extends StatefulWidget {
  const InfluencerFilterExample({Key? key}) : super(key: key);

  @override
  State<InfluencerFilterExample> createState() =>
      _InfluencerFilterExampleState();
}

class _InfluencerFilterExampleState extends State<InfluencerFilterExample> {
  List<FilterModel> _filters = [];

  @override
  void initState() {
    super.initState();
    // Initialize with default filters
    _filters = FilterUtils.createDefaultFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Influencer Filter Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: BlocBuilder<InfluencersBloc, InfluencersState>(
        builder: (context, state) {
          if (state is InfluencersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InfluencersLoaded) {
            return Column(
              children: [
                // Filter status
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                          'Active Filters: ${FilterUtils.getEnabledFiltersCount(_filters)}'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _clearAllFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                // Influencers list
                Expanded(
                  child: ListView.builder(
                    itemCount: state.influencers.length,
                    itemBuilder: (context, index) {
                      final influencer = state.influencers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child:
                              Text(influencer['profile']?['pseudo']?[0] ?? '?'),
                        ),
                        title: Text(
                            '@${influencer['profile']?['pseudo'] ?? 'unknown'}'),
                        subtitle:
                            Text(influencer['profile']?['zone'] ?? 'Unknown'),
                        trailing: Text(
                            '⭐ ${influencer['averageRating']?.toStringAsFixed(1) ?? '0.0'}'),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is InfluencersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  ElevatedButton(
                    onPressed: _loadInfluencers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('No data'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadInfluencers,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _loadInfluencers() {
    context.read<InfluencersBloc>().add(FilterInfluencers(filters: _filters));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Influencers'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zone filter
              _buildFilterSwitch(
                'Zone Filter',
                'Filter by location zone',
                _filters.any((f) => f.key == 'zone' && f.enabled),
                (enabled) => _toggleZoneFilter(enabled),
              ),
              const SizedBox(height: 16),
              // Search filter
              _buildFilterSwitch(
                'Search Filter',
                'Search by name or bio',
                _filters.any((f) => f.key == 'search' && f.enabled),
                (enabled) => _toggleSearchFilter(enabled),
              ),
              const SizedBox(height: 16),
              // Limit filter
              _buildFilterSwitch(
                'Limit Filter',
                'Number of items per page',
                _filters.any((f) => f.key == 'limit' && f.enabled),
                (enabled) => _toggleLimitFilter(enabled),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadInfluencers();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _toggleZoneFilter(bool enabled) {
    setState(() {
      final existingZoneFilterIndex =
          _filters.indexWhere((f) => f.key == 'zone');
      if (existingZoneFilterIndex != -1) {
        _filters[existingZoneFilterIndex] =
            _filters[existingZoneFilterIndex].copyWith(enabled: enabled);
      } else if (enabled) {
        _filters.add(FilterUtils.createZoneFilter('Paris', enabled: true));
      }
    });
  }

  void _toggleSearchFilter(bool enabled) {
    setState(() {
      final existingSearchFilterIndex =
          _filters.indexWhere((f) => f.key == 'search');
      if (existingSearchFilterIndex != -1) {
        _filters[existingSearchFilterIndex] =
            _filters[existingSearchFilterIndex].copyWith(enabled: enabled);
      } else if (enabled) {
        _filters.add(FilterUtils.createSearchFilter('beauty', enabled: true));
      }
    });
  }

  void _toggleLimitFilter(bool enabled) {
    setState(() {
      final existingLimitFilterIndex =
          _filters.indexWhere((f) => f.key == 'limit');
      if (existingLimitFilterIndex != -1) {
        _filters[existingLimitFilterIndex] =
            _filters[existingLimitFilterIndex].copyWith(enabled: enabled);
      } else if (enabled) {
        _filters.add(FilterUtils.createLimitFilter(5, enabled: true));
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filters = FilterUtils.createDefaultFilters();
    });
    _loadInfluencers();
  }
}

/// Example of creating filters programmatically
class FilterCreationExamples {
  static void demonstrateFilterCreation() {
    // Example 1: Create filters from the provided structure
    final filters = [
      FilterUtils.createFilter(
        key: 'zone',
        value: 'hello',
        description: null,
        enabled: false,
        equals: true,
      ),
      FilterUtils.createFilter(
        key: 'limit',
        value: '10',
        description: null,
        enabled: false,
        equals: true,
      ),
      FilterUtils.createFilter(
        key: 'page',
        value: '1',
        description: null,
        enabled: false,
        equals: true,
      ),
    ];

    // Example 2: Enable specific filters
    final enabledFilters = filters.map((filter) {
      if (filter.key == 'zone') {
        return filter.copyWith(enabled: true, value: 'Paris');
      }
      if (filter.key == 'limit') {
        return filter.copyWith(enabled: true, value: '20');
      }
      return filter;
    }).toList();

    // Example 3: Create filters from a map
    final filtersFromMap = FilterUtils.createFiltersFromMap({
      'zone': 'Marseille',
      'limit': '15',
      'page': '2',
      'search': 'beauty',
    });
    print('Filters from map: ${filtersFromMap.length}');

    // Example 4: Get only enabled filters
    final activeFilters = FilterUtils.getEnabledFilters(enabledFilters);

    print('Total filters: ${filters.length}');
    print('Enabled filters: ${activeFilters.length}');
    print('Has enabled filters: ${FilterUtils.hasEnabledFilters(filters)}');
  }
}
