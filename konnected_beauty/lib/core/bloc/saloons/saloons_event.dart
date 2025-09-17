abstract class SaloonsEvent {}

class LoadSaloons extends SaloonsEvent {
  final String? search;
  final int page;
  final int limit;

  LoadSaloons({
    this.search,
    this.page = 1,
    this.limit = 10,
  });
}

class LoadMoreSaloons extends SaloonsEvent {
  final String? search;
  final int page;
  final int limit;

  LoadMoreSaloons({
    this.search,
    required this.page,
    this.limit = 10,
  });
}

class RefreshSaloons extends SaloonsEvent {
  final String? search;
  final int limit;

  RefreshSaloons({
    this.search,
    this.limit = 10,
  });
}

class SearchSaloons extends SaloonsEvent {
  final String search;

  SearchSaloons(this.search);
}
