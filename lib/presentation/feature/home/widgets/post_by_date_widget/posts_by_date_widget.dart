import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:admin_dashboard/core/common/loading_dialog_manager.dart';
import 'package:admin_dashboard/core/constants/app_texts.dart';
import 'package:admin_dashboard/core/di/usecase_provider.dart';
import 'package:admin_dashboard/domain/entity/api_response.dart';
import 'package:admin_dashboard/domain/entity/post/post.dart';
import 'package:admin_dashboard/domain/entity/post/post_by_date_request.dart';
import 'package:admin_dashboard/domain/entity/post/posts_response.dart';
import 'package:admin_dashboard/presentation/feature/home/widgets/post_by_date_widget/post_list_widget.dart';
import 'package:admin_dashboard/core/common/dialog_helper.dart';
import '../../provider/posts_provider.dart';

class PostByDateWidget extends ConsumerStatefulWidget {
  const PostByDateWidget({super.key});

  @override
  ConsumerState<PostByDateWidget> createState() => _PostByDateWidgetState();
}

class _PostByDateWidgetState extends ConsumerState<PostByDateWidget> {
  TextEditingController _dateInputController = TextEditingController();
  late TextEditingController _maxInputController;

  @override
  void initState() {
    super.initState();
    _maxInputController = TextEditingController(text: "30");
    _dateInputController.text = DateFormat("yyyy-MM-dd").format(DateTime.now());

    Future.microtask(() => _fetchPostByDate());
  }
  void _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
              onPrimary: Color.fromARGB(255, 9, 107, 187),
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat("yyyy-MM-dd").format(pickedDate);
      setState(() {
        _dateInputController.text = formattedDate;
      });
    }
  }

  void _fetchPostByDate() async {
    if (_dateInputController.text.isEmpty) {
      showInfoDialog(
          context: context,
          title: AppTexts.wait,
          message: AppTexts.dateNotSelectedErrorMessage);
      return;
    } else if (_maxInputController.text.isEmpty) {
      showInfoDialog(
          context: context,
          title: AppTexts.wait,
          message: AppTexts.maxValueNotEnteredErrorMessage
      );
      return;
    }
    LoadingDialog.show(context, AppTexts.loadingPostMessage);
    final PostByDateRequest postByDateRequest = PostByDateRequest(
        date: _dateInputController.text,
        max: int.parse(_maxInputController.text));
    final getPostByDateUseCase = ref.read(getPostByDateUseCaseProvider);
    getPostByDateUseCase.setParam(postByDateRequest);
    final ApiResponse apiResponse = await getPostByDateUseCase.execute();
    if (!mounted) return;

    LoadingDialog.hide(context);
    if (apiResponse is SuccessResponse) {
      final PostsResponse postsResponse =
          (apiResponse as SuccessResponse<PostsResponse>).data;
      // ref.read(postsProvider.notifier).clear();
      ref.read(postsProvider.notifier).addAllPosts(postsResponse.posts);
      final filteredPosts = ref.read(postsProvider).where((p) => p.date == _dateInputController.text).toList();
     // if no post found msg vl be like this
      if (filteredPosts.isEmpty) {
        showInfoDialog(
          context: context,
          title: 'No Posts Found',
          message:
          'No posts found for date: ${_dateInputController.text}',
        );
      }
    } else {
      showInfoDialog(
        context: context,
        title: 'Error',
        message: 'Failed to fetch posts. Please try again.',
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final allPosts = ref.watch(postsProvider);
    final posts = allPosts.where((p) => p.date == _dateInputController.text).toList();
    return Container(
      padding: const EdgeInsets.only(
        top: 32,
        bottom: 0,
        left: 16,
        right: 16,
      ),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 50,
                child: TextFormField(
                  onTap: () {
                    _showDatePicker(context);
                  },
                  readOnly: true,
                  controller: _dateInputController,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: Icon(Icons.calendar_month_sharp),
                    border: OutlineInputBorder(),
                    label: Text(
                      AppTexts.selectDate,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  width: 24
              ),
             SizedBox(
                width: 70,
                height: 40,
                child: TextFormField(
                  controller: _maxInputController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                    label: Text(
                      AppTexts.max,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  width: 24
              ),
              ElevatedButton(
                onPressed: _fetchPostByDate,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black),
                child: const Text(
                  AppTexts.getPostByDate,
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(width: 16),

              if (posts.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    ref.read(postsProvider.notifier).removePostsByDate(_dateInputController.text);
                    _dateInputController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          if (_dateInputController.text.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing posts for: ${_dateInputController.text} '
                    '(${posts.length} found)',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 8),
          PostListWidget(allPost: posts),
        ],
      ),
    );
  }
}
