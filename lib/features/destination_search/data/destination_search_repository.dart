class DestinationSearchRepository {
  String lastQuery = '';
  void remember(String query) => lastQuery = query;
}
