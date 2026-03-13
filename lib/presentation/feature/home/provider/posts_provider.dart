import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/domain/entity/post/post.dart';

final postsProvider = StateNotifierProvider<PostsNotifier, List<Post>>((ref) => PostsNotifier());

class PostsNotifier extends StateNotifier<List<Post>> {
  PostsNotifier() : super([]);

  void addPost(Post post) {
    if (!state.any((p) => p.title == post.title && p.date == post.date)) {
      state = [...state, post];
    }
  }

  void addAllPosts(List<Post> posts) {
    for (var post in posts) {
      addPost(post);
    }
  }

  void setPosts(List<Post> posts) {
    state = posts;
  }

  void removePostsByDate(String date) {
    state = state.where((p) => p.date != date).toList();
  }
}