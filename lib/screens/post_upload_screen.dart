import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/services/post_service.dart';
import 'package:campus_pulse/services/storage_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/auth/auth_manager.dart';
import 'package:campus_pulse/theme.dart';

class PostUploadScreen extends StatefulWidget {
  const PostUploadScreen({super.key});

  @override
  State<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends State<PostUploadScreen> {
  final _challengeController = TextEditingController();
  Uint8List? _selectedBytes;
  bool _isUploading = false;
  User? _currentUser;

  final List<String> _challengeSuggestions = [
    'StudyVibes',
    'CampusLife',
    'ExamSuccess',
    'TeamWork',
    'Fitness',
    'Art',
    'Food',
    'Sports',
    'StudyGroup',
    'CampusEvents',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _challengeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await DefaultAuthManager.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
    });

    // Debug: Print user info
    if (user != null) {
      // print('Current user loaded: ${user.id}, ${user.email}, ${user.nickname}');
    } else {
      // print('No current user found');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Read bytes for both mobile and web
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: $e',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    }
  }

  Future<void> _uploadPost() async {
    // Prevent double submission
    if (_isUploading) {
      // print('Upload already in progress, ignoring request');
      return;
    }

    if (_selectedBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an image',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
      return;
    }

    // No title required - just image and optional tag

    if (_currentUser == null) {
      // print('Error: Current user is null');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User not found. Please login again.',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
      return;
    }

    // print('Uploading post for user: ${_currentUser!.id}');

    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      String? imageUrl;

      // Use the selected bytes for upload
      final Uint8List? bytes = _selectedBytes;

      if (bytes == null) {
        throw Exception('No image data available');
      }

      // Upload using bytes - works on both web and mobile
      imageUrl = await StorageService.instance.uploadPostImage(
        imageBytes: bytes,
        userId: _currentUser!.id,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      await PostService.instance.createPost(
        userId: _currentUser!.id,
        imageUrl: imageUrl,
        caption: null, // No caption needed
        challengeTag: _challengeController.text.trim().isNotEmpty
            ? _challengeController.text.trim()
            : null,
      );

      // Notify state changes for instant rebuild
      AppStateManager.instance.notifyPostsUpdated();
      AppStateManager.instance.notifyProfileUpdated();
      AppStateManager.instance.notifyLeaderboardUpdated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post uploaded successfully! 🔥',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.mintGreen,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to trigger profile refresh
    } catch (e) {
      // print('Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload post: $e',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwipzeeColors.lightGray,
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: SwipzeeTypography.heading3.copyWith(
            color: SwipzeeColors.darkGray,
          ),
        ),
        backgroundColor: SwipzeeColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: SwipzeeColors.darkGray,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: Text(
              'Post',
              style: SwipzeeTypography.buttonMedium.copyWith(
                color: _isUploading
                    ? SwipzeeColors.mediumGray
                    : SwipzeeColors.fireOrange,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: SwipzeeColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SwipzeeColors.mediumGray.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null || _selectedBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _selectedBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: SwipzeeColors.mediumGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select image',
                            style: SwipzeeTypography.bodyLarge.copyWith(
                              color: SwipzeeColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Challenge Tag Input
            Text(
              'Challenge Tag (Optional)',
              style: SwipzeeTypography.labelLarge.copyWith(
                color: SwipzeeColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _challengeController,
              decoration: InputDecoration(
                hintText: 'e.g., StudyVibes, CampusLife, ExamSuccess',
                hintStyle: SwipzeeTypography.bodyMedium.copyWith(
                  color: SwipzeeColors.mediumGray,
                ),
                prefixText: '#',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: SwipzeeColors.mediumGray.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: SwipzeeColors.mediumGray.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: SwipzeeColors.accentPurple,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: SwipzeeColors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Challenge Suggestions
            Text(
              'Popular Challenges:',
              style: SwipzeeTypography.labelMedium.copyWith(
                color: SwipzeeColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _challengeSuggestions.map((challenge) {
                return GestureDetector(
                  onTap: () {
                    _challengeController.text = challenge;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SwipzeeColors.softPink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SwipzeeColors.softPink.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '#$challenge',
                      style: SwipzeeTypography.labelSmall.copyWith(
                        color: SwipzeeColors.softPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Upload Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadPost,
              style: SwipzeeStyles.fireButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              child: _isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: SwipzeeColors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Uploading...',
                          style: SwipzeeTypography.buttonLarge,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.upload,
                          color: SwipzeeColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Post',
                          style: SwipzeeTypography.buttonLarge,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
