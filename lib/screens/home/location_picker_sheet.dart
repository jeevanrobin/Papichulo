import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
      final label = await _orderApi.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
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
    _confirmAndReturn(
      latitude: result.latitude,
      longitude: result.longitude,
      label: result.label,
    );
  }

  void _selectRecent(LocationHistoryEntry entry) {
    _confirmAndReturn(
      latitude: entry.latitude,
      longitude: entry.longitude,
      label: entry.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = AddressService.instance.addresses;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Container(
          color: const Color(0xFF0F0F0F),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: 'Search for area, street name...',
        hintStyle: const TextStyle(color: Colors.white54),
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
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onQueryChanged('');
                    },
                  )),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _gold),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildDetectRow() {
    return ListTile(
      onTap: _useCurrentLocation,
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.08),
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
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: const Text(
        'Using GPS',
        style: TextStyle(color: Colors.white60),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSavedTile(SavedAddress address) {
    return Card(
      color: Colors.white.withOpacity(0.03),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _selectSavedAddress(address),
        leading: Icon(
          Icons.location_on_outlined,
          color: _gold,
        ),
        title: Text(
          address.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          address.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white60),
      ),
    );
  }

  Widget _buildSuggestionTile(GeocodeResult result) {
    return Card(
      color: Colors.white.withOpacity(0.03),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _selectSuggestion(result),
        leading: const Icon(Icons.place_outlined, color: _gold),
        title: Text(
          result.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white60),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }
}
