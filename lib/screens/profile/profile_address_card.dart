import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import '../../models/saved_address.dart';

/// Card widget displaying a saved delivery address.
class ProfileAddressCard extends StatelessWidget {
  static const Color _gold = Color(0xFFF5C842);
  static const Color _border = Color(0x1AFFFFFF);

  final SavedAddress address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProfileAddressCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _labelIcon {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _gold.withValues(alpha: 0.65) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + label + actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_labelIcon, color: _gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined,
                    color: _gold.withValues(alpha: 0.7), size: 18),
                tooltip: 'Edit',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _gold.withValues(alpha: 0.55)),
              ),
              child: const Text(
                'Selected for delivery',
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Address text
          Text(
            address.fullAddress,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSelected ? null : onSelect,
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.near_me_outlined,
                size: 16,
              ),
              label: Text(isSelected ? 'Selected' : 'Deliver Here'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isSelected ? Colors.black : _gold,
                backgroundColor:
                    isSelected ? _gold : Colors.transparent,
                side: BorderSide(
                  color: isSelected ? _gold : _gold.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
