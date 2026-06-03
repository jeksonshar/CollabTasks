import 'dart:ui';

import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class TaskFormatterEditorSection extends StatefulWidget {
  final GlobalKey editorKey;
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final String formattingTitle;
  final String editorPlaceholder;

  const TaskFormatterEditorSection({
    super.key,
    required this.editorKey,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.formattingTitle,
    required this.editorPlaceholder,
  });

  @override
  State<TaskFormatterEditorSection> createState() => _TaskFormatterEditorSectionState();
}

class _TaskFormatterEditorSectionState extends State<TaskFormatterEditorSection> with L10nMixin {
  final ScrollController _toolbarScrollController = ScrollController();

  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _toolbarScrollController.addListener(_updateToolbarScrollIndicators);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateToolbarScrollIndicators();
      }
    });
  }

  @override
  void dispose() {
    _toolbarScrollController
      ..removeListener(_updateToolbarScrollIndicators)
      ..dispose();
    super.dispose();
  }

  void _updateToolbarScrollIndicators() {
    if (!_toolbarScrollController.hasClients) return;

    final position = _toolbarScrollController.position;
    final canLeft = position.pixels > 0;
    final canRight = position.pixels < position.maxScrollExtent;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Title for toolbar
        // Align(
        //   alignment: Alignment.centerLeft,
        //   child: Text(
        //     widget.formattingTitle,
        //     style: AppTextStyles.bold16Black87Roboto,
        //   ),
        // ),
        // const SizedBox(height: 2),

        /// 🔹 Toolbar
        SizedBox(
          height: 48,
          child: Stack(
            children: [
              // the toolbar itself with scrolling capabilities
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                ),
                child: SingleChildScrollView(
                  controller: _toolbarScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      quill.QuillSimpleToolbar(
                        controller: widget.controller,
                        config: const quill.QuillSimpleToolbarConfig(
                          showDividers: true,
                          showBoldButton: true,
                          showItalicButton: true,
                          showStrikeThrough: true,
                          showHeaderStyle: true,
                          showColorButton: true,
                          showBackgroundColorButton: true,
                          showFontSize: true,
                          showListNumbers: true,
                          showListBullets: true,
                          showListCheck: false,
                          showDirection: false,
                          showSearchButton: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Left gradient
              if (_canScrollLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              // Right gradient
              if (_canScrollRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                            Theme.of(context).colorScheme.surface,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // const SizedBox(height: 8),

        /// 🔹 Label for editor
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            localization.descriptionField,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),

        /// 🔹 Editor with min and max height, scrollable
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
          child: Scrollbar(
            controller: widget.scrollController,
            thumbVisibility: true, // show not only on scroll, but always
            child: Container(
              key: widget.editorKey,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: quill.QuillEditor(
                controller: widget.controller,
                focusNode: widget.focusNode,
                scrollController: widget.scrollController,
                config: quill.QuillEditorConfig(
                  placeholder: widget.editorPlaceholder,
                  expands: false,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
