abstract class SaloonsState {}

class SaloonsInitial extends SaloonsState {}

class SaloonsLoading extends SaloonsState {}

class SaloonsLoadingMore extends SaloonsState {
  final List<dynamic> saloons;

  SaloonsLoadingMore(this.saloons);
}

class SaloonsLoaded extends SaloonsState {
  final List<dynamic> saloons;
  final String message;
  final int currentPage;
  final bool hasMore;
  final String? currentSearch;
  final int total;
  final int totalPages;

  SaloonsLoaded({
    required this.saloons,
    required this.message,
    required this.currentPage,
    required this.hasMore,
    this.currentSearch,
    required this.total,
    required this.totalPages,
  });
}

class SaloonsError extends SaloonsState {
  final String message;
  final int? statusCode;

  SaloonsError(this.message, {this.statusCode});
}
