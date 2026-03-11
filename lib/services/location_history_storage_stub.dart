String? _memoryHistory;

String? readHistory() => _memoryHistory;

void writeHistory(String json) {
  _memoryHistory = json;
}
