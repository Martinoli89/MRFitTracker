import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ExerciseNoteSheet extends StatefulWidget {
  final String exerciseName;
  final String initialNote;

  const ExerciseNoteSheet({
    super.key,
    required this.exerciseName,
    required this.initialNote,
  });

  @override
  State<ExerciseNoteSheet> createState() =>
      _ExerciseNoteSheetState();
}

class _ExerciseNoteSheetState extends State<ExerciseNoteSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialNote,
    );

    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _saveNote() {
    Navigator.of(context).pop(
      _controller.text.trim(),
    );
  }

  void _deleteNote() {
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight =
        MediaQuery.viewInsetsOf(context).bottom;

    final hasExistingNote =
        widget.initialNote.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(
          milliseconds: 180,
        ),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          keyboardHeight + 20,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Nota del ejercicio',
                style: TextStyle(
                  color: AppColors.wineStrong,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.exerciseName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Anota algo útil para la próxima vez: técnica, sensaciones o algún ajuste.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 5,
                textCapitalization:
                    TextCapitalization.sentences,
                textInputAction:
                    TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      'Ejemplo: mantener los codos más cerrados...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(19),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(19),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(19),
                    borderSide: const BorderSide(
                      color: AppColors.wineStrong,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: const Text(
                    'Guardar nota',
                  ),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),
              if (hasExistingNote) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _deleteNote,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Quitar nota',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}