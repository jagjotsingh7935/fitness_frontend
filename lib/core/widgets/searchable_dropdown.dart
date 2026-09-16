import 'package:flutter/material.dart';

/// Represents an item in the [SearchableDropdown].
class SearchableDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchableDropdownItem<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A responsive, dark-themed searchable dropdown that replaces bulky native dropdowns.
///
/// Looks and behaves like a clean [TextFormField] / [DropdownButtonFormField] in forms,
/// but opens an auto-focused, instant-filtering search bottom sheet (or dialog on wide screens)
/// to make searching through large lists (300+ items) effortless without layout obstruction.
class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<SearchableDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? searchHint;
  final bool isRequired;
  final bool enabled;
  final bool allowClear;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final String? Function(T?)? validator;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.searchHint,
    this.isRequired = false,
    this.enabled = true,
    this.allowClear = false,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.validator,
  });

  SearchableDropdownItem<T>? get _selectedItem {
    if (value == null) return null;
    try {
      return items.firstWhere((item) => item.value == value);
    } catch (_) {
      return null;
    }
  }

  void _openSearchPicker(BuildContext context) {
    if (!enabled || items.isEmpty) return;

    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      showDialog<T>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: _SearchPickerContent<T>(
              title: labelText ?? hintText ?? 'Select Option',
              searchHint: searchHint ?? 'Search...',
              items: items,
              selectedValue: value,
              onSelected: (val) {
                Navigator.of(ctx).pop();
                onChanged?.call(val);
              },
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161B30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: _SearchPickerContent<T>(
              title: labelText ?? hintText ?? 'Select Option',
              searchHint: searchHint ?? 'Search...',
              items: items,
              selectedValue: value,
              onSelected: (val) {
                Navigator.of(ctx).pop();
                onChanged?.call(val);
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (fieldState) {
        final hasError = fieldState.hasError;

        return InkWell(
          onTap: enabled ? () => _openSearchPicker(context) : null,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: hintText ?? 'Select an option',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: fillColor ?? const Color(0xFF111425),
              errorText: hasError ? fieldState.errorText : null,
              errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFFF5252) : Colors.white12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5C07B), width: 1.5),
              ),
              contentPadding: contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allowClear && selected != null && enabled)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.white38),
                      onPressed: () {
                        fieldState.didChange(null);
                        onChanged?.call(null);
                      },
                    ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            isEmpty: selected == null,
            child: selected != null
                ? Text(
                    selected.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _SearchPickerContent<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  const _SearchPickerContent({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_SearchPickerContent<T>> createState() => _SearchPickerContentState<T>();
}

class _SearchPickerContentState<T> extends State<_SearchPickerContent<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SearchableDropdownItem<T>> get _filteredItems {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      final labelMatch = item.label.toLowerCase().contains(q);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(q) ?? false;
      return labelMatch || subtitleMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // Title and count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title.replaceAll('*', '').trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.items.length} total',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Search Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE5C07B), size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF0F1322),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5C07B), width: 1.5),
              ),
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
        ),

        const SizedBox(height: 6),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Colors.white38, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? 'No options available'
                              : 'No results found for "$_query"',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Colors.white10,
                    indent: 8,
                    endIndent: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = item.value == widget.selectedValue;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected
                          ? const Color(0xFF00F5A0).withValues(alpha: 0.1)
                          : Colors.transparent,
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00F5A0) : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00F5A0),
                              size: 20,
                            )
                          : null,
                      onTap: () => widget.onSelected(item.value),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
