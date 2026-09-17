import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/category_dto.dart';
import '../../data/models/client_profile_dto.dart';
import '../state/client_profile_cubit.dart';

class FitnessGoalsSheet {
  static Future<void> show(
    BuildContext context, {
    required ClientProfileDto? profile,
    required List<CategoryDto> allCategories,
    VoidCallback? onSaved,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocProvider.value(
          value: context.read<ClientProfileCubit>(),
          child: _FitnessGoalsModal(
            profile: profile,
            allCategories: allCategories,
            onSaved: onSaved,
          ),
        );
      },
    );
  }
}

class _FitnessGoalsModal extends StatefulWidget {
  const _FitnessGoalsModal({
    required this.profile,
    required this.allCategories,
    this.onSaved,
  });

  final ClientProfileDto? profile;
  final List<CategoryDto> allCategories;
  final VoidCallback? onSaved;

  @override
  State<_FitnessGoalsModal> createState() => _FitnessGoalsModalState();
}

class _FitnessGoalsModalState extends State<_FitnessGoalsModal> {
  final Set<int> _selectedIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile?.categories != null) {
      for (final cat in widget.profile!.categories) {
        _selectedIds.add(cat.id);
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final success = await context.read<ClientProfileCubit>().updateProfile({
        'category_ids': _selectedIds.toList(),
      });
      if (success && mounted) {
        widget.onSaved?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fitness goals updated successfully!'),
            backgroundColor: Color(0xFF00F5A0),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final categories = widget.allCategories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1326),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.track_changes_rounded,
                    color: Color(0xFF00F5A0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'My Fitness Goals',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select your target training & fitness objectives',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141829),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF00F5A0),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your coach and system algorithms customize workouts and calorie targets based on your chosen goals.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Target Categories (${_selectedIds.length} selected)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No goal categories found from server.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((cat) {
                        final isSel = _selectedIds.contains(cat.id);
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              if (isSel) {
                                _selectedIds.remove(cat.id);
                              } else {
                                _selectedIds.add(cat.id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
                                  : const Color(0xFF141829),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF00F5A0)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSel ? 1.5 : 1,
                              ),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F5A0).withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  size: 16,
                                  color: isSel ? const Color(0xFF00F5A0) : Colors.white38,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSel ? const Color(0xFF00F5A0) : Colors.white70,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Button Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E1E),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Save Fitness Goals',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
