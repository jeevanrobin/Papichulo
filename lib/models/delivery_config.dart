class DeliveryConfig {
  final double storeLatitude;
  final double storeLongitude;
  final double radiusKm;
  final DateTime? updatedAt;

  const DeliveryConfig({
    required this.storeLatitude,
    required this.storeLongitude,
    required this.radiusKm,
    this.updatedAt,
  });

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) {
    return DeliveryConfig(
      storeLatitude: (json['storeLatitude'] as num?)?.toDouble() ?? 17.385044,
      storeLongitude: (json['storeLongitude'] as num?)?.toDouble() ?? 78.486671,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 10,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }
}
