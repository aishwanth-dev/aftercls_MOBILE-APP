import 'package:flutter/material.dart';
import 'package:campus_pulse/models/shared_post.dart';
import 'package:campus_pulse/services/share_service.dart';
import 'package:campus_pulse/widgets/share_post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoadResult {
  final List<SharedPost> posts;
  final int initialIndex;
  _LoadResult(this.posts, this.initialIndex);
}

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late Future<_LoadResult> _loadFuture;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadPostsAndIndex();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<_LoadResult> _loadPostsAndIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedIndex = prefs.getInt('lastViewedPostIndex') ?? 0;
      final posts = await ShareService.instance.getAllSharedPosts();
      // New posts should be on the right side. old n ... - old1 - old2 - old3 - new
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return _LoadResult(posts, lastViewedIndex);
    } catch (e) {
      print("Error loading posts or index: $e");
      // Returning an empty list and default index in case of error
      return _LoadResult([], 0);
    }
  }

  void _addPost() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Post'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await ShareService.instance.createSharedPost(text: controller.text);
                  Navigator.of(context).pop();
                  setState(() {
                    _loadFuture = _loadPostsAndIndex().then((result) {
                      // After adding a new post, jump to the last page.
                      if (_pageController != null && _pageController!.hasClients) {
                        final newIndex = result.posts.length - 1;
                        _pageController!.jumpToPage(newIndex);
                      }
                      return result;
                    });
                  });
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Share', style: TextStyle(color: Color(0xFF808080))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF808080)),
      ),
      body: FutureBuilder<_LoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading posts', style: TextStyle(color: Color(0xFF808080))));
          } else if (!snapshot.hasData || snapshot.data!.posts.isEmpty) {
            return const Center(child: Text('No posts yet', style: TextStyle(color: Color(0xFF808080))));
          } else {
            final result = snapshot.data!;
            final posts = result.posts;
            final initialIndex = result.initialIndex < posts.length ? result.initialIndex : 0;
            _pageController = PageController(initialPage: initialIndex);

            return PageView.builder(
              controller: _pageController,
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return SharePostCard(post: posts[index]);
              },
              onPageChanged: (index) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('lastViewedPostIndex', index);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPost,
        child: const Icon(Icons.add),
      ),
    );
  }
}