class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  }) : hasMore = (page * pageSize) < totalCount;

  bool get isFirstPage => page == 1;
  bool get isLastPage => !hasMore;
  int get totalPages => (totalCount / pageSize).ceil();
}
