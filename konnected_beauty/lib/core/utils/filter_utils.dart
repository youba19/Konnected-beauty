import 'package:uuid/uuid.dart';
import '../models/filter_model.dart';

class FilterUtils {
  static const _uuid = Uuid();

  /// Create a filter object with the specified parameters
  static FilterModel createFilter({
    required String key,
    required String value,
    String? description,
    bool enabled = true,
    bool equals = true,
  }) {
    return FilterModel(
      key: key,
      value: value,
      description: description,
      enabled: enabled,
      equals: equals,
      uuid: _uuid.v4(),
    );
  }

  /// Create a zone filter
  static FilterModel createZoneFilter(String zone, {bool enabled = true}) {
    return createFilter(
      key: 'zone',
      value: zone,
      description: 'Filter by location zone',
      enabled: enabled,
    );
  }

  /// Create a page filter
  static FilterModel createPageFilter(int page, {bool enabled = true}) {
    return createFilter(
      key: 'page',
      value: page.toString(),
      description: 'Page number for pagination',
      enabled: enabled,
    );
  }

  /// Create a limit filter
  static FilterModel createLimitFilter(int limit, {bool enabled = true}) {
    return createFilter(
      key: 'limit',
      value: limit.toString(),
      description: 'Number of items per page',
      enabled: enabled,
    );
  }

  /// Create a search filter
  static FilterModel createSearchFilter(String search, {bool enabled = true}) {
    return createFilter(
      key: 'search',
      value: search,
      description: 'Search query',
      enabled: enabled,
    );
  }

  /// Create a sort order filter
  static FilterModel createSortOrderFilter(String sortOrder,
      {bool enabled = true}) {
    return createFilter(
      key: 'sortOrder',
      value: sortOrder,
      description: 'Sort order (ASC/DESC)',
      enabled: enabled,
    );
  }

  /// Create default filters for initial load
  static List<FilterModel> createDefaultFilters({
    int page = 1,
    int limit = 10,
    String sortOrder = 'DESC',
  }) {
    return [
      createPageFilter(page),
      createLimitFilter(limit),
      createSortOrderFilter(sortOrder),
    ];
  }

  /// Create filters from a map of parameters
  static List<FilterModel> createFiltersFromMap(Map<String, dynamic> params) {
    final filters = <FilterModel>[];

    params.forEach((key, value) {
      if (value != null) {
        filters.add(createFilter(
          key: key,
          value: value.toString(),
          enabled: true,
        ));
      }
    });

    return filters;
  }

  /// Get enabled filters from a list
  static List<FilterModel> getEnabledFilters(List<FilterModel> filters) {
    return filters.where((filter) => filter.enabled).toList();
  }

  /// Toggle a filter's enabled state
  static FilterModel toggleFilter(FilterModel filter) {
    return filter.copyWith(enabled: !filter.enabled);
  }

  /// Update a filter's value
  static FilterModel updateFilterValue(FilterModel filter, String newValue) {
    return filter.copyWith(value: newValue);
  }

  /// Check if any filters are enabled
  static bool hasEnabledFilters(List<FilterModel> filters) {
    return filters.any((filter) => filter.enabled);
  }

  /// Get the count of enabled filters
  static int getEnabledFiltersCount(List<FilterModel> filters) {
    return filters.where((filter) => filter.enabled).length;
  }
}
