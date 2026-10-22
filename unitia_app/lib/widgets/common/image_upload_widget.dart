import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

/// Widget de avatar con botón de edición. Al tocar sube una imagen a
/// Firebase Storage y llama [onUploaded] con la nueva URL.
class ImageUploadWidget extends StatefulWidget {
  final String? currentUrl;
  final String storagePath;
  final double size;
  final double borderRadius;
  final IconData placeholder;
  final ValueChanged<String> onUploaded;

  const ImageUploadWidget({
    super.key,
    required this.currentUrl,
    required this.storagePath,
    required this.onUploaded,
    this.size = 88,
    this.borderRadius = 24,
    this.placeholder = Icons.image_rounded,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final _storage = StorageService();
  bool _uploading = false;

  Future<void> _pick() async {
    setState(() => _uploading = true);
    try {
      final url = await _storage.pickAndUpload(path: widget.storagePath);
      if (url != null && mounted) widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _pick,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _uploading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.5),
                  )
                : widget.currentUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.currentUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          widget.placeholder,
                          color: AppColors.primary,
                          size: widget.size * 0.45,
                        ),
                      )
                    : Center(
                        child: Icon(
                          widget.placeholder,
                          color: AppColors.primary,
                          size: widget.size * 0.45,
                        ),
                      ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
