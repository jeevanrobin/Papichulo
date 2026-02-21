class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  static const String adminKey = String.fromEnvironment(
    'ADMIN_API_KEY',
    defaultValue: '',
  );

  static List<String> candidateBaseUrls() {
    final candidates = <String>[];

    void addIfMissing(String value) {
      if (value.isEmpty) return;
      if (!candidates.contains(value)) {
        candidates.add(value);
      }
    }

    addIfMissing(baseUrl);

    Uri? uri;
    try {
      uri = Uri.parse(baseUrl);
    } catch (_) {
      return candidates;
    }

    final host = uri.host.toLowerCase();
    final isLocalHost =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    if (!isLocalHost) {
      return candidates;
    }

    final hostVariants = <String>{host};
    if (host == 'localhost') {
      hostVariants.add('127.0.0.1');
    } else if (host == '127.0.0.1') {
      hostVariants.add('localhost');
    } else if (host == '::1') {
      hostVariants
        ..add('localhost')
        ..add('127.0.0.1');
    }

    final ports = <int>{};
    if (uri.hasPort) {
      ports.add(uri.port);
    }
    ports
      ..add(3001)
      ..add(3011);

    for (final hostVariant in hostVariants) {
      for (final port in ports) {
        addIfMissing(uri.replace(host: hostVariant, port: port).toString());
      }
    }

    return candidates;
  }
}
