class SavedAddress {
  final String id;
  final String label; // 'Home', 'Work', 'Other'
  final String address;
  final double latitude;
  final double longitude;
  final String? doorFlatNo;
  final String? landmark;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.doorFlatNo,
    this.landmark,
  });

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    String? doorFlatNo,
    String? landmark,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      doorFlatNo: doorFlatNo ?? this.doorFlatNo,
      landmark: landmark ?? this.landmark,
    );
  }

  /// Full formatted address including door/flat and landmark.
  String get fullAddress {
    final parts = <String>[];
    if (doorFlatNo != null && doorFlatNo!.isNotEmpty) parts.add(doorFlatNo!);
    if (landmark != null && landmark!.isNotEmpty) parts.add(landmark!);
    parts.add(address);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (doorFlatNo != null) 'doorFlatNo': doorFlatNo,
        if (landmark != null) 'landmark': landmark,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Other',
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      doorFlatNo: json['doorFlatNo'] as String?,
      landmark: json['landmark'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedAddress &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
