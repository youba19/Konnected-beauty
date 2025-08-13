# Salon Services API - Multi-Filter Pagination Examples

## Overview

The salon services API supports multiple filters simultaneously with pagination and infinite scroll. All filters are persistent across paginated requests.

## Base URL
```
http://srv950342.hstgr.cloud:3000/salon-service
```

## API Endpoint
```
GET {{baseUrl}}/salon-service?minPrice=0&maxPrice=100&page=1&search=text
```

## Supported Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `page` | int | Page number for pagination | `page=1` |
| `minPrice` | double | Minimum price filter | `minPrice=0` |
| `maxPrice` | double | Maximum price filter | `maxPrice=100` |
| `search` | string | Text search filter | `search=massage` |

## Authentication
All requests require a Bearer token in the Authorization header:
```
Authorization: Bearer <access_token>
```

## Example Requests

### 1. Initial Load (Page 1)
```
GET http://srv950342.hstgr.cloud:3000/salon-service?page=1
```

### 2. Price Range Filter
```
GET http://srv950342.hstgr.cloud:3000/salon-service?minPrice=50&maxPrice=200&page=1
```

### 3. Text Search
```
GET http://srv950342.hstgr.cloud:3000/salon-service?search=massage&page=1
```

### 4. Combined Filters
```
GET http://srv950342.hstgr.cloud:3000/salon-service?minPrice=0&maxPrice=100&search=text&page=1
```

### 5. Next Page with Persistent Filters
```
GET http://srv950342.hstgr.cloud:3000/salon-service?minPrice=0&maxPrice=100&search=text&page=2
```

## Response Format

```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "name": "Swedish Massage",
      "price": 80,
      "description": "Relaxing full body massage"
    }
  ],
  "message": "Services retrieved successfully",
  "statusCode": 200,
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 50,
    "itemsPerPage": 10,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

## Pagination Metadata

The `pagination` object contains:
- `currentPage`: Current page number
- `totalPages`: Total number of pages
- `totalItems`: Total number of items
- `itemsPerPage`: Items per page
- `hasNextPage`: Whether there's a next page
- `hasPreviousPage`: Whether there's a previous page

## Implementation Features

### ✅ Filter Persistence
- All active filters are maintained across pagination
- When loading page 2, 3, etc., the same filters are applied

### ✅ Combined Filtering
- Multiple filters can be used simultaneously
- Price range + search + pagination all work together

### ✅ Infinite Scroll
- Automatically loads next page when user scrolls to bottom
- Maintains all current filters when loading more data

### ✅ Search Relevance
- Results are sorted by relevance when search is applied
- Text search works across service names and descriptions

### ✅ Error Handling
- 401 Unauthorized errors trigger automatic token refresh
- Network errors are handled gracefully
- Retry logic for failed requests

## Usage Examples

### Flutter Implementation

```dart
// Initial load
context.read<SalonServicesBloc>().add(LoadSalonServices());

// Apply filters
context.read<SalonServicesBloc>().add(FilterSalonServices(
  minPrice: 50,
  maxPrice: 200,
  searchQuery: "massage",
));

// Search only
context.read<SalonServicesBloc>().add(SearchSalonServices(
  searchQuery: "facial",
));

// Load more (automatic via scroll)
context.read<SalonServicesBloc>().add(LoadMoreSalonServices(
  page: 2,
  searchQuery: "massage",
  minPrice: 50,
  maxPrice: 200,
));
```

### API Call Examples

```bash
# Get all services (page 1)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://srv950342.hstgr.cloud:3000/salon-service?page=1"

# Filter by price range
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://srv950342.hstgr.cloud:3000/salon-service?minPrice=0&maxPrice=100&page=1"

# Search for services
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://srv950342.hstgr.cloud:3000/salon-service?search=massage&page=1"

# Combined filters
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://srv950342.hstgr.cloud:3000/salon-service?minPrice=50&maxPrice=200&search=facial&page=1"

# Next page with same filters
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://srv950342.hstgr.cloud:3000/salon-service?minPrice=50&maxPrice=200&search=facial&page=2"
```

## State Management

The Flutter app maintains filter state across pagination:

```dart
class SalonServicesLoaded extends SalonServicesState {
  final List<dynamic> services;
  final String message;
  final int currentPage;
  final bool hasMoreData;
  final String? currentSearch;      // Persistent search filter
  final int? currentMinPrice;       // Persistent min price filter
  final int? currentMaxPrice;       // Persistent max price filter
}
```

## Debug Information

The implementation includes comprehensive debug logging:

```
📄 === BLOC: LOAD MORE SALON SERVICES ===
📄 Requested Page: 2
📄 Search Query: massage
📄 Min Price: 50
📄 Max Price: 200

🔗 === API CALL ===
🔗 URL: http://srv950342.hstgr.cloud:3000/salon-service?minPrice=50&maxPrice=200&search=massage&page=2
🔗 Query Params: {minPrice: 50, maxPrice: 200, search: massage, page: 2}

📄 === LOAD MORE RESULT ===
📄 Success: true
📄 New Services Count: 10
📄 Pagination: {currentPage: 2, totalPages: 5}

📄 === UPDATING STATE ===
📄 Previous Services Count: 10
📄 New Services Count: 10
📄 Total Services Count: 20
📄 New Current Page: 2
📄 New Has More Data: true
```

This implementation provides a complete solution for multi-filter pagination with infinite scroll, maintaining all requirements for filter persistence, combined filtering, and proper pagination metadata.
