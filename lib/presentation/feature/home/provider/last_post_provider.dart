import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/domain/entity/post/post.dart';

final lastPostProvider = StateProvider<Post?>((ref) => null);