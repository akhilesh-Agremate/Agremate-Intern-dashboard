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
import 'package:admin_dashboard/core/constants/app_constants.dart';

class PostByDateWidget extends ConsumerStatefulWidget {
  const PostByDateWidget({super.key});

  @override
  ConsumerState<PostByDateWidget> createState() => _PostByDateWidgetState();
}

class _PostByDateWidgetState extends ConsumerState<PostByDateWidget> {
  TextEditingController _dateInputController = TextEditingController();
  late TextEditingController _maxInputController;
  final List<Post> _filteredPost = [];

  @override
  void initState() {
    _maxInputController = TextEditingController(text: "30");
    super.initState();
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
    if (!mounted) {
      return;
    }
    LoadingDialog.hide(context);
    if (apiResponse is SuccessResponse) {
      final PostsResponse postsResponse =
          (apiResponse as SuccessResponse<PostsResponse>).data;
      _filteredPost.clear();
      setState(() {
        _filteredPost.addAll(postsResponse.posts);
      });
      if (_filteredPost.isEmpty) {
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

              if (_filteredPost.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filteredPost.clear();
                      _dateInputController.clear();
                    });
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
                    '(${_filteredPost.length} found)',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 8),
          PostListWidget(allPost: _filteredPost),
        ],
      ),
    );
  }
}