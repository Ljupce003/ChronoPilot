import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/presentation/screens/location_picker_screen.dart';
import 'package:flutter/material.dart';

/// Location input section
///
/// Small reusable UI that exposes location selection for event forms. Shows
/// the currently selected [EventLocation] (if any) and provides quick actions
/// to use the device location or open the full map picker screen
/// (`LocationPickerScreen`). The selected value is returned through
/// [onChanged].
class LocationInputSection extends StatelessWidget {
  final EventLocation? location;
  final ValueChanged<EventLocation?> onChanged;

  const LocationInputSection({
    super.key,
    required this.location,
    required this.onChanged,
  });

  Future<void> _openPicker(
    BuildContext context, {
    bool autoUseCurrentLocation = false,
  }) async {
    final picked = await Navigator.push<EventLocation?>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: location,
          autoUseCurrentLocation: autoUseCurrentLocation,
        ),
      ),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text(
        'Location',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        if (location != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(location!.name),
            subtitle: Text(
              '${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openPicker(context, autoUseCurrentLocation: true),
                icon: const Icon(Icons.my_location),
                label: const Text('Use my current location'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openPicker(context),
                icon: const Icon(Icons.map),
                label: const Text('Choose from map'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

