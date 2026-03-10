import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import '../../models/saved_address.dart';
import '../../services/address_service.dart';

/// Result returned by the dialog: whether the user chose to save
/// the address and the resolved details.
class DeliveryLocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? doorFlatNo;
  final String? landmark;
  final String? label;
  final String? savedAddressId;
  final bool shouldSave;

  const DeliveryLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.doorFlatNo,
    this.landmark,
    this.label,
    this.savedAddressId,
    this.shouldSave = false,
  });
}

/// Dialog that shows the resolved address and optionally allows the user
/// to add more details (door/flat no, landmark) and save the address.
///
/// Can operate in **edit** mode when [existingAddress] is provided.
class SetDeliveryLocationDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String resolvedAddress;
  final SavedAddress? existingAddress; // non-null = edit mode

  const SetDeliveryLocationDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.resolvedAddress,
    this.existingAddress,
  });

  @override
  State<SetDeliveryLocationDialog> createState() =>
      _SetDeliveryLocationDialogState();
}

class _SetDeliveryLocationDialogState extends State<SetDeliveryLocationDialog>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _bg = Color(0xFF1A1A1A);
  static const Color _inputBg = Color(0xFF131313);

  bool _expanded = false;
  String _selectedLabel = 'Home';
  late final TextEditingController _doorCtrl;
  late final TextEditingController _landmarkCtrl;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  bool get _isEditMode => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);

    if (_isEditMode) {
      final e = widget.existingAddress!;
      _doorCtrl = TextEditingController(text: e.doorFlatNo ?? '');
      _landmarkCtrl = TextEditingController(text: e.landmark ?? '');
      _selectedLabel = e.label;
      _expanded = true;
      _expandCtrl.value = 1.0;
    } else {
      _doorCtrl = TextEditingController();
      _landmarkCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _doorCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  void _skipAndProceed() {
    Navigator.of(context).pop(DeliveryLocationResult(
      latitude: widget.latitude,
      longitude: widget.longitude,
      address: widget.resolvedAddress,
      savedAddressId: null,
      shouldSave: false,
    ));
  }

  void _saveAndProceed() {
    final door = _doorCtrl.text.trim().isEmpty ? null : _doorCtrl.text.trim();
    final landmark =
        _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim();
    final parts = <String>[
      if (door != null) door,
      if (landmark != null) landmark,
      widget.resolvedAddress,
    ];
    final formattedAddress = parts.join(', ');
    String? savedAddressId;

    final result = DeliveryLocationResult(
      latitude: widget.latitude,
      longitude: widget.longitude,
      address: formattedAddress,
      doorFlatNo: door,
      landmark: landmark,
      label: _selectedLabel,
      savedAddressId: null,
      shouldSave: true,
    );

    if (_isEditMode) {
      savedAddressId = widget.existingAddress!.id;
      final updated = widget.existingAddress!.copyWith(
        address: widget.resolvedAddress,
        latitude: widget.latitude,
        longitude: widget.longitude,
        doorFlatNo: result.doorFlatNo ?? '',
        landmark: result.landmark ?? '',
        label: _selectedLabel,
      );
      AddressService.instance.updateAddress(updated);
    } else {
      savedAddressId = DateTime.now().millisecondsSinceEpoch.toString();
      final newAddr = SavedAddress(
        id: savedAddressId,
        label: _selectedLabel,
        address: widget.resolvedAddress,
        latitude: widget.latitude,
        longitude: widget.longitude,
        doorFlatNo: result.doorFlatNo,
        landmark: result.landmark,
      );
      AddressService.instance.addAddress(newAddr);
    }
    Navigator.of(context).pop(
      DeliveryLocationResult(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
        doorFlatNo: result.doorFlatNo,
        landmark: result.landmark,
        label: result.label,
        savedAddressId: savedAddressId,
        shouldSave: result.shouldSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapPlaceholder(),
              _buildAddressSection(),
              _buildExpandableForm(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _gold.withValues(alpha: 0.15),
            _bg,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: _gold, size: 48),
          const SizedBox(height: 8),
          Text(
            'Set delivery location',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: _gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.resolvedAddress,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableForm() {
    return SizeTransition(
      sizeFactor: _expandAnim,
      axisAlignment: -1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: _gold.withValues(alpha: 0.1)),
            const SizedBox(height: 8),
            _buildTextField(_doorCtrl, 'Door / Flat No.',
                Icons.door_front_door_outlined),
            const SizedBox(height: 12),
            _buildTextField(
                _landmarkCtrl, 'Landmark', Icons.landscape_outlined),
            const SizedBox(height: 16),
            // Label chips
            Text('Save as',
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: ['Home', 'Work', 'Other'].map((label) {
                final selected = _selectedLabel == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: _gold,
                    backgroundColor: _inputBg,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color:
                          selected ? _gold : _gold.withValues(alpha: 0.2),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedLabel = label),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _gold.withValues(alpha: 0.6), size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          if (!_expanded && !_isEditMode) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipAndProceed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SKIP & ADD LATER',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleExpand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('ADD MORE DETAILS',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveAndProceed,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isEditMode
                      ? 'UPDATE ADDRESS'
                      : 'SAVE ADDRESS & PROCEED',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            if (!_isEditMode) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _toggleExpand,
                child: Text('COLLAPSE',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
