import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/saved_address.dart';
import '../../services/address_service.dart';
import '../../services/location_history_service.dart';
import '../../services/order_api_service.dart';
import 'set_delivery_location_dialog.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String label;
  final String? savedAddressId;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.savedAddressId,
  });
}

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  static const _gold = Color(0xFFFFD700);
  static const _bg = Color(0xFF0D0D0D);
  static const _cardBg = Color(0xFF151515);
  static const _cardBorder = Color(0x33FFD700);
  static const _heading = Colors.white;
  static const _subtle = Color(0xFFB5B5B5);
  final _orderApi = OrderApiService();
  final _searchCtrl = TextEditingController();
  final _debounceMs = 320;
  Timer? _debounce;
  bool _isSearching = false;
  bool _isDetecting = false;
  List<GeocodeResult> _suggestions = const [];
  List<LocationHistoryEntry> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    await AddressService.instance.loadAddresses();
    await LocationHistoryService.instance.load();
    if (!mounted) return;
    setState(() => _recent = LocationHistoryService.instance.entries);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(Duration(milliseconds: _debounceMs), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _orderApi.searchLocations(query);
      if (!mounted) return;
      setState(() => _suggestions = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to search locations: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isDetecting) return;
    setState(() => _isDetecting = true);
    try {
      final position = await _getCurrentPosition();
      String label = '';
      try {
        label = await _orderApi.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        label =
            'Current location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      }
      await _confirmAndReturn(
        latitude: position.latitude,
        longitude: position.longitude,
        label: label.isEmpty ? 'Current location' : label,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyLocationError(e)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _confirmAndReturn({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final result = await showDialog<DeliveryLocationResult>(
      context: context,
      builder: (_) => SetDeliveryLocationDialog(
        latitude: latitude,
        longitude: longitude,
        resolvedAddress: label,
      ),
    );
    if (!mounted || result == null) return;

    String? savedId = result.savedAddressId;
    if (result.shouldSave && savedId != null) {
      AddressService.instance.setSelectedAddress(savedId);
    }
    LocationHistoryService.instance.add(
      LocationHistoryEntry(
        label: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      ),
    );
    Navigator.of(context).pop(
      LocationPickerResult(
        latitude: result.latitude,
        longitude: result.longitude,
        label: result.address,
        savedAddressId: savedId,
      ),
    );
  }

  Future<_PinnedLocation?> _showMapPinDialog({
    required String seedLabel,
    required double latitude,
    required double longitude,
  }) async {
    LatLng point = LatLng(latitude, longitude);
    String displayLabel = seedLabel;
    bool isResolving = false;

    return showDialog<_PinnedLocation>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> resolve(LatLng p) async {
              setState(() {
                isResolving = true;
                displayLabel =
                    'Selected location (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})';
              });
              try {
                final label = await _orderApi.reverseGeocode(
                  latitude: p.latitude,
                  longitude: p.longitude,
                );
                if (!dialogContext.mounted) return;
                setState(() {
                  displayLabel = label.isEmpty
                      ? 'Selected location (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})'
                      : label;
                });
              } catch (_) {
                setState(() {
                  displayLabel =
                      'Selected location (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})';
                });
              } finally {
                if (dialogContext.mounted) {
                  setState(() => isResolving = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.location_on, color: _gold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Fine-tune on map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 320,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: point,
                            initialZoom: 14,
                            onTap: (_, p) {
                              point = p;
                              resolve(p);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'papichulo',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 38,
                                  height: 38,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: _gold,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isResolving) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      _PinnedLocation(
                        latitude: point.latitude,
                        longitude: point.longitude,
                        label: displayLabel,
                      ),
                    );
                  },
                  child: const Text(
                    'Use this location',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Position> _getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception(
          'Location services are disabled. Turn on GPS/location and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  String _friendlyLocationError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('permission')) {
      return 'Location permission denied. Allow access and try again.';
    }
    if (raw.contains('disabled')) {
      return 'Location services are off. Enable location and retry.';
    }
    return 'Unable to detect location right now. Enter address manually.';
  }

  void _selectSavedAddress(SavedAddress address) {
    AddressService.instance.setSelectedAddress(address.id);
    Navigator.of(context).pop(
      LocationPickerResult(
        latitude: address.latitude,
        longitude: address.longitude,
        label: address.fullAddress,
        savedAddressId: address.id,
      ),
    );
  }

  void _selectSuggestion(GeocodeResult result) {
    _pickOnMapAndConfirm(
      seedLabel: result.label,
      latitude: result.latitude,
      longitude: result.longitude,
    );
  }

  void _selectRecent(LocationHistoryEntry entry) {
    _pickOnMapAndConfirm(
      seedLabel: entry.label,
      latitude: entry.latitude,
      longitude: entry.longitude,
    );
  }

  Future<void> _pickOnMapAndConfirm({
    required String seedLabel,
    required double latitude,
    required double longitude,
  }) async {
    final pinned = await _showMapPinDialog(
      seedLabel: seedLabel,
      latitude: latitude,
      longitude: longitude,
    );
    if (pinned == null) return;
    await _confirmAndReturn(
      latitude: pinned.latitude,
      longitude: pinned.longitude,
      label: pinned.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = AddressService.instance.addresses;

    return Material(
      color: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.25),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
          bottom: Radius.circular(18),
        ),
        child: Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Choose delivery location',
                      style: TextStyle(
                        color: _heading,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _subtle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildDetectRow(),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSectionTitle('Saved addresses'),
                      if (saved.isEmpty)
                        _emptyText('No saved addresses yet.')
                      else
                        ...saved.map(_buildSavedTile),
                      const SizedBox(height: 12),
                      if (_suggestions.isNotEmpty) ...[
                        _buildSectionTitle('Suggestions'),
                        ..._suggestions.map(_buildSuggestionTile),
                        const SizedBox(height: 12),
                      ],
                      _buildSectionTitle('Recent searches'),
                      if (_recent.isEmpty)
                        _emptyText('Recent picks will appear here.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recent
                              .map(
                                (r) => ActionChip(
                                  label: Text(
                                    r.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _selectRecent(r),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  avatar: const Icon(
                                    Icons.history,
                                    size: 18,
                                    color: _gold,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onQueryChanged,
      style: const TextStyle(color: _heading),
      decoration: InputDecoration(
        filled: true,
        fillColor: _cardBg,
        hintText: 'Search for area, street name...',
        hintStyle: const TextStyle(color: _subtle),
        prefixIcon: const Icon(Icons.search, color: _gold),
        suffixIcon: _isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _gold,
                  ),
                ),
              )
            : (_searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: _subtle),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onQueryChanged('');
                    },
                  )),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _gold.withOpacity(0.9), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildDetectRow() {
    return ListTile(
      onTap: _useCurrentLocation,
      tileColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: _gold.withOpacity(0.12),
        child: _isDetecting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _gold,
                ),
              )
            : const Icon(Icons.my_location, color: _gold),
      ),
        title: const Text(
          'Get current location',
          style: TextStyle(
            color: _heading,
            fontWeight: FontWeight.w700,
          ),
        ),
      subtitle: Text(
        _isDetecting
            ? 'Requesting permission...'
            : 'Using GPS',
        style: const TextStyle(color: _subtle),
      ),
      trailing: const Icon(Icons.chevron_right, color: _subtle),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _heading,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSavedTile(SavedAddress address) {
    return Card(
      color: _cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cardBorder),
      ),
      child: ListTile(
        onTap: () => _selectSavedAddress(address),
        leading: Icon(
          Icons.location_on_outlined,
          color: _gold,
        ),
        title: Text(
          address.label,
          style: const TextStyle(
            color: _heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          address.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _subtle),
        ),
        trailing: const Icon(Icons.chevron_right, color: _subtle),
      ),
    );
  }

  Widget _buildSuggestionTile(GeocodeResult result) {
    return Card(
      color: _cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cardBorder),
      ),
      child: ListTile(
        onTap: () => _selectSuggestion(result),
        leading: const Icon(Icons.place_outlined, color: _gold),
        title: Text(
          result.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: _subtle),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(color: _subtle),
      ),
    );
  }
}

class _PinnedLocation {
  final double latitude;
  final double longitude;
  final String label;
  const _PinnedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}
