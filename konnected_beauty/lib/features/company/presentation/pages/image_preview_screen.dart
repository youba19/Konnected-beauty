import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  final List<Map<String, dynamic>>?
      imageData; // For existing images with metadata

  const ImagePreviewScreen({
    Key? key,
    required this.images,
    this.initialIndex = 0,
    this.imageData,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.x,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          // Optional: Add more actions like share, delete, etc.
          const SizedBox(width: 16),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        builder: (context, index) {
          final imageFile = widget.images[index];

          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(imageFile),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'image_$index',
            ),
            onTapUp: (context, details, controllerValue) {
              // Optional: Handle tap to show/hide UI
            },
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
      // Bottom info panel (optional)
      bottomNavigationBar: widget.imageData != null &&
              _currentIndex < widget.imageData!.length
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black87,
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image name
                  if (widget.imageData![_currentIndex]['url'] != null) ...[
                    Text(
                      _getImageName(widget.imageData![_currentIndex]['url']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Image info
                  Text(
                    'Image ${_currentIndex + 1} of ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  String _getImageName(String url) {
    if (url.isEmpty) return 'Image';

    final urlParts = url.split('/');
    if (urlParts.isNotEmpty) {
      final fileName = urlParts.last;
      final cleanName = fileName.split('?').first;
      if (cleanName.isNotEmpty && !cleanName.startsWith('existing_')) {
        return cleanName;
      }
    }
    return 'Image';
  }
}
