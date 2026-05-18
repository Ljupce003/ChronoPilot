import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EventLocationMapCard extends StatelessWidget {
  final EventLocation location;

  const EventLocationMapCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
             leading: const Icon(Icons.place, color: AppColors.primary),
             title: Text(location.name),
             subtitle: InkWell(
               onTap: () async {
                 final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');
                 try {
                   await launchUrl(uri, mode: LaunchMode.externalApplication);
                 } catch (_) {
                   // ignore errors silently; optionally show snackbar
                 }
               },
               child: Text(
                 '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                 style: const TextStyle(decoration: TextDecoration.underline, color: AppColors.primary),
               ),
             ),
           ),
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ljupchoangelovski.chrono_pilot',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                       point: point,
                       width: 48,
                       height: 48,
                       child: const Icon(
                         Icons.location_pin,
                         color: AppColors.primary,
                         size: 48,
                       ),
                     ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

