import 'dart:io';

import 'package:chrono_pilot/service/event_media_service.dart';
import 'package:flutter/material.dart';

class ImageInputSection extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onChanged;

  const ImageInputSection({
    super.key,
    required this.imagePath,
    required this.onChanged,
  });

  Future<void> _pickFromCamera(BuildContext context) async {
    final picked = await EventMediaService().pickFromCamera();
    if (picked != null) {
      onChanged(picked);
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picked = await EventMediaService().pickFromGallery();
    if (picked != null) {
      onChanged(picked);
    }
  }

  Widget _buildPreview(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48),
            SizedBox(height: 8),
            Text('No image selected'),
          ],
        ),
      );
    }

    final file = File(imagePath!);
    if (!file.existsSync()) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 48),
            SizedBox(height: 8),
            Text('Image not available'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        file,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text(
        'Image',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        _buildPreview(context),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickFromCamera(context),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Take a photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFromGallery(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from gallery'),
              ),
            ),
          ],
        ),
        if (imagePath != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.clear),
                  label: const Text('Remove image'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

