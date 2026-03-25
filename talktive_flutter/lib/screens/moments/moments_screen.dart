import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/blocked_users_provider.dart';
import '../../providers/moments_provider.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_moment_card.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/duo/duo_floor_requirement_dialog.dart';

/// Duolingo-style Moments screen - Photo feed
class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  final _captionController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _imageBytes; // For cross-platform preview
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    final image = await ref.read(mediaServiceProvider).pickImage();
    if (image != null) {
      final bytes = await image.readAsBytes();
      setModalState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  void _handleCreatePressed() async {
    debugPrint('MomentsScreen: [_handleCreatePressed] FAB tapped');
    HapticFeedback.lightImpact();

    Resident? currentResident = ref.read(currentResidentProvider).value;

    if (currentResident == null) {
      debugPrint(
        'MomentsScreen: currentResident is null, waiting for future...',
      );
      try {
        currentResident = await ref.read(currentResidentProvider.future);
      } catch (e) {
        debugPrint('MomentsScreen: Error waiting for resident: $e');
        if (mounted) {
          DuoSnackBarHelper.showError(
            context,
            'Failed to load profile. Please try again.',
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
    }

    if (currentResident == null) {
      debugPrint('MomentsScreen: Resident still null after waiting');
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Resident profile not found.');
      }
      return;
    }

    // Mute check
    if (DuoFloorHelper.isMuted(currentResident)) {
      debugPrint('MomentsScreen: Resident is muted');
      DuoSnackBarHelper.showError(
        context,
        DuoFloorHelper.getMuteReason(currentResident),
      );
      return;
    }
    if (!mounted) return;

    final effectiveFloor = DuoFloorHelper.computeFloor(currentResident);
    debugPrint('MomentsScreen: Effective floor: $effectiveFloor');

    if (effectiveFloor < 2) {
      DuoFloorRequirementDialog.show(
        context,
        message:
            'You must reach Floor 2 to post moments. Keep interacting to climb higher! (Current Floor: $effectiveFloor)',
        requiredFloor: 2,
      );
      return;
    }

    _showCreateDialog();
  }

  void _postMoment(StateSetter setModalState) async {
    if (_selectedImage == null) {
      DuoSnackBarHelper.showError(context, 'Please select an image first! 📸');
      return;
    }

    final caption = _captionController.text.trim();

    debugPrint('Moments: [UI] Starting post process...');
    setModalState(() {
      _isUploading = true;
    });
    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload image to storage
      debugPrint('Moments: [UI] Uploading image to Firebase...');
      final uploadResult = await ref
          .read(mediaServiceProvider)
          .uploadFile(_selectedImage!, 'moments');

      if (uploadResult == null) {
        throw Exception('Failed to upload image. Result was null.');
      }
      debugPrint(
        'Moments: [UI] Image uploaded successfully. URL: ${uploadResult.url}',
      );

      // 2. Post moment to backend
      debugPrint('Moments: [UI] Sending post request to Serverpod...');
      final client = ref.read(clientProvider);
      await client.moment.postMoment(
        imageUrl: uploadResult.url,
        caption: caption,
        fileSize: uploadResult.sizeInBytes,
      );
      debugPrint('Moments: [UI] Status: Post successful on server.');

      if (mounted) {
        debugPrint('Moments: [UI] Closing dialog...');
        Navigator.of(context).pop();

        // Refresh the feed in the background
        ref.read(momentsProvider.notifier).refresh();

        _captionController.clear();
        if (mounted) {
          setState(() {
            _selectedImage = null;
            _imageBytes = null;
            _isUploading = false;
          });
        }
        debugPrint('Moments: [UI] Dialog closed and state reset.');
        DuoSnackBarHelper.showSuccess(context, 'Moment posted! 🎉');
      }
    } catch (e, stack) {
      debugPrint('Moments: [CRITICAL ERROR] Failed to post: $e');
      debugPrint('Moments: Stack trace: $stack');
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('Floor')) {
          DuoFloorRequirementDialog.show(context, message: errorMessage);
        } else {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    } finally {
      if (mounted) {
        setModalState(() {
          _isUploading = false;
        });
        setState(() {
          _isUploading = false;
        });
      }
      debugPrint('Moments: [UI] Post process finished.');
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.duoRadiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.secondaryGradient,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.duoRadiusLarge),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppTheme.duoSpacingSmall),
                      const Expanded(
                        child: Text(
                          'New Moment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image selector
                      GestureDetector(
                        onTap: _isUploading
                            ? null
                            : () => _pickImage(setModalState),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(
                              AppTheme.duoRadiusMedium,
                            ),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.duoRadiusMedium - 2,
                                  ),
                                  child: _imageBytes != null
                                      ? Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Select photo',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Max size: 5MB',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.duoSpacingLarge),
                      DuoInput(
                        controller: _captionController,
                        labelText: 'Caption',
                        hintText: "What's happening?",
                        maxLines: 4,
                        maxLength: 200,
                        enabled: !_isUploading,
                      ),
                    ],
                  ),
                ),
              ),
              // Post button
              Padding(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                child: SafeArea(
                  top: false,
                  child: DuoButton(
                    text: 'Post Moment',
                    icon: Icons.send,
                    width: double.infinity,
                    isLoading: _isUploading,
                    onPressed: () => _postMoment(setModalState),
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DuoPageScaffold(
      emoji: '📸',
      title: 'Moments',
      subtitle: 'Stories from the building',
      trailingHeader: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DuoRefreshButton(
            onRefresh: () async {
              ref.invalidate(momentsProvider);
              ref.invalidate(momentLikesProvider);
            },
          ),
        ],
      ),
      gradient: AppTheme.secondaryGradient,
      floatingActionButton: FloatingActionButton(
        heroTag: 'moments_fab',
        onPressed: _handleCreatePressed,
        backgroundColor: AppTheme.secondaryColor,
        elevation: 6,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ).animate().scale(delay: 300.ms, duration: 200.ms),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final momentsAsync = ref.watch(momentsProvider);
    final blockedUsers = ref.watch(blockedUsersProvider).value ?? [];
    final likedMoments = ref.watch(momentLikesProvider).value ?? {};

    return momentsAsync.when(
      data: (moments) {
        if (moments.isEmpty) {
          return DuoEmptyState(
            icon: Icons.photo_library,
            title: 'No moments yet',
            subtitle: 'Share your first photo!',
            buttonText: 'Create Moment',
            onButtonPressed: _handleCreatePressed,
          );
        }

        final filteredMoments = moments
            .where((m) => !blockedUsers.contains(m.authorId.toString()))
            .toList();

        if (filteredMoments.isEmpty && moments.isNotEmpty) {
          return const DuoEmptyState(
            icon: Icons.visibility_off,
            title: 'No moments to show',
            subtitle:
                'The only moments available are from users you have blocked.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(momentsProvider);
            ref.invalidate(momentLikesProvider);
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppTheme.duoSpacingMedium,
              left: AppTheme.duoSpacingMedium,
              right: AppTheme.duoSpacingMedium,
              bottom: AppTheme.contentBottomPadding,
            ),
            itemCount: filteredMoments.length,
            itemBuilder: (context, index) {
              final moment = filteredMoments[index];
              return DuoMomentCard(
                moment: moment,
                index: index,
                isLiked: likedMoments.contains(moment.id),
                onLike: () =>
                    _toggleLike(moment, likedMoments.contains(moment.id)),
                onComment: () {
                  HapticFeedback.lightImpact();
                  context.push('/moments/detail', extra: moment);
                },
                onAuthorTap: () {
                  context.push('/user/${moment.authorId}');
                },
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/moments/detail', extra: moment);
                },
              );
            },
          ),
        );
      },
      loading: () => const DuoLoadingIndicator(),
      error: (error, stack) => Center(
        child: DuoCard(
          margin: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              Text(
                'Error: $error',
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              DuoButton(
                text: 'Retry',
                onPressed: () => ref.invalidate(momentsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(Moment moment, bool currentlyLiked) async {
    if (moment.id == null) return;

    // Use optimistic UI update
    ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);

    try {
      await ref
          .read(momentsProvider.notifier)
          .toggleLike(moment.id!, currentlyLiked);
    } catch (e) {
      // Revert if error
      ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);
      if (mounted) DuoSnackBarHelper.showError(context, e.toString());
    }
  }
}
