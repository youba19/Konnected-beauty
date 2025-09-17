# Influencers API Filter System

## Overview

The Influencers API now supports a comprehensive filter system that allows dynamic filtering with multiple parameters. The system is designed to be scalable and reusable, following the same pattern as the Services screen.

## Architecture

### 1. FilterModel Class
Represents individual filter objects with the following structure:
```dart
class FilterModel {
  final String key;        // Filter parameter name (e.g., 'zone', 'limit', 'page')
  final String value;      // Filter value (e.g., 'Paris', '10', '1')
  final String? description; // Optional description
  final bool enabled;      // Whether the filter is active
  final bool equals;       // Comparison type (always true for now)
  final String uuid;       // Unique identifier
}
```

### 2. InfluencersService
- **`getInfluencersWithFilters()`**: New method that accepts a list of FilterModel objects
- **`getInfluencers()`**: Legacy method maintained for backward compatibility
- Automatically builds query parameters from enabled filters
- Ensures required parameters (page, limit, sortOrder) are always present

### 3. InfluencersBloc
- **`FilterInfluencers` event**: New event for applying filters
- **`currentFilters`**: Added to InfluencersLoaded state to track active filters
- Maintains all existing events for backward compatibility

### 4. FilterUtils
Utility class providing helper methods for creating and managing filters:
- `createFilter()`: Create individual filters
- `createZoneFilter()`, `createPageFilter()`, etc.: Convenience methods
- `createDefaultFilters()`: Create standard filter set
- `getEnabledFilters()`: Extract only enabled filters
- `toggleFilter()`: Toggle filter enabled state

## Usage Examples

### Basic Usage

```dart
// 1. Create filters
final filters = [
  FilterUtils.createZoneFilter('Paris', enabled: true),
  FilterUtils.createLimitFilter(20, enabled: true),
  FilterUtils.createPageFilter(1, enabled: true),
];

// 2. Apply filters
context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));
```

### Advanced Usage

```dart
// Create filters from the exact structure you provided
final filters = [
  FilterModel(
    key: 'zone',
    value: 'hello',
    description: null,
    enabled: true,  // Only enabled filters are applied
    equals: true,
    uuid: 'b39d646a-d839-4bcf-ab09-eb95456fbf14',
  ),
  FilterModel(
    key: 'limit',
    value: '10',
    description: null,
    enabled: true,
    equals: true,
    uuid: '45dd7ef0-fdf5-43d2-9cc2-0cc934243d8f',
  ),
  FilterModel(
    key: 'page',
    value: '1',
    description: null,
    enabled: false, // This filter will be ignored
    equals: true,
    uuid: 'c4dbe054-6e80-4915-b862-484f2ec0eeda',
  ),
];

// Apply filters
context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));
```

### Dynamic Filter Management

```dart
class InfluencerFilterManager {
  List<FilterModel> _filters = [];

  // Add a new filter
  void addFilter(String key, String value) {
    _filters.add(FilterUtils.createFilter(
      key: key,
      value: value,
      enabled: true,
    ));
  }

  // Toggle a filter's enabled state
  void toggleFilter(String key) {
    _filters = _filters.map((filter) {
      if (filter.key == key) {
        return FilterUtils.toggleFilter(filter);
      }
      return filter;
    }).toList();
  }

  // Update a filter's value
  void updateFilterValue(String key, String newValue) {
    _filters = _filters.map((filter) {
      if (filter.key == key) {
        return FilterUtils.updateFilterValue(filter, newValue);
      }
      return filter;
    }).toList();
  }

  // Apply filters
  void applyFilters(BuildContext context) {
    context.read<InfluencersBloc>().add(FilterInfluencers(filters: _filters));
  }

  // Get only enabled filters
  List<FilterModel> get activeFilters => FilterUtils.getEnabledFilters(_filters);
}
```

## API URL Generation

The system automatically generates query parameters from enabled filters:

### Example 1: Single Filter
```dart
final filters = [
  FilterUtils.createZoneFilter('Paris', enabled: true),
  FilterUtils.createPageFilter(1, enabled: true),
  FilterUtils.createLimitFilter(10, enabled: true),
];
// Generates: /influencer?zone=Paris&page=1&limit=10&sortOrder=DESC
```

### Example 2: Multiple Filters
```dart
final filters = [
  FilterUtils.createZoneFilter('Marseille', enabled: true),
  FilterUtils.createSearchFilter('beauty', enabled: true),
  FilterUtils.createLimitFilter(15, enabled: true),
  FilterUtils.createPageFilter(2, enabled: true),
];
// Generates: /influencer?zone=Marseille&search=beauty&limit=15&page=2&sortOrder=DESC
```

### Example 3: Mixed Enabled/Disabled
```dart
final filters = [
  FilterUtils.createZoneFilter('Paris', enabled: true),
  FilterUtils.createSearchFilter('fashion', enabled: false), // Ignored
  FilterUtils.createLimitFilter(20, enabled: true),
  FilterUtils.createPageFilter(1, enabled: false), // Ignored, but page=1 added automatically
];
// Generates: /influencer?zone=Paris&limit=20&page=1&sortOrder=DESC
```

## Supported Filter Keys

| Key | Type | Description | Example Value |
|-----|------|-------------|---------------|
| `zone` | String | Location zone filter | "Paris", "Marseille" |
| `search` | String | Text search filter | "beauty", "fashion" |
| `limit` | Integer | Items per page | "10", "20", "50" |
| `page` | Integer | Page number | "1", "2", "3" |
| `sortOrder` | String | Sort direction | "ASC", "DESC" |

## Integration with Existing Code

The filter system is fully backward compatible:

1. **Existing BLoC events** continue to work unchanged
2. **Legacy service methods** are preserved
3. **New filter functionality** is additive only

### Migration Example

```dart
// Old way (still works)
context.read<InfluencersBloc>().add(LoadInfluencers(
  page: 1,
  limit: 10,
  zone: 'Paris',
  search: 'beauty',
));

// New way (more flexible)
final filters = [
  FilterUtils.createPageFilter(1),
  FilterUtils.createLimitFilter(10),
  FilterUtils.createZoneFilter('Paris'),
  FilterUtils.createSearchFilter('beauty'),
];
context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));
```

## Error Handling

The system includes comprehensive error handling:

- **Invalid filter values**: Gracefully handled with fallbacks
- **Network errors**: Proper error states emitted
- **Authentication issues**: Handled by HTTP interceptor
- **Empty results**: Proper empty state handling

## Testing

Use the provided example file (`lib/examples/influencer_filter_example.dart`) to test the filter functionality:

```dart
// Run the example
import 'package:konnected_beauty/examples/influencer_filter_example.dart';

// In your app
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => InfluencerFilterExample()),
);
```

## Future Extensibility

The system is designed to easily support new filter types:

1. **Add new filter keys** in the service
2. **Create convenience methods** in FilterUtils
3. **Update UI components** to support new filters
4. **No changes needed** to core BLoC or service logic

### Adding a New Filter Type

```dart
// 1. Add to FilterUtils
static FilterModel createRatingFilter(double minRating, {bool enabled = true}) {
  return createFilter(
    key: 'minRating',
    value: minRating.toString(),
    description: 'Minimum rating filter',
    enabled: enabled,
  );
}

// 2. Use in your app
final filters = [
  FilterUtils.createRatingFilter(4.0, enabled: true),
  FilterUtils.createZoneFilter('Paris', enabled: true),
];
```

## Performance Considerations

- **Efficient query building**: Only enabled filters are processed
- **Minimal state updates**: BLoC only emits when necessary
- **Cached results**: HTTP interceptor handles caching
- **Pagination support**: Maintains existing pagination logic

This filter system provides a robust, scalable foundation for influencer filtering that can grow with your application's needs.
