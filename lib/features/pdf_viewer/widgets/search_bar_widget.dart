import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/features/pdf_viewer/providers/search_provider.dart';

/// Search bar widget for PDF text search
class SearchBarWidget extends StatefulWidget {
  final VoidCallback? onClose;

  const SearchBarWidget({super.key, this.onClose});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final state = searchProvider.state;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Search icon
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),

                // Search text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search in PDF...',
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _controller.clear();
                                searchProvider.clearSearch();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      // Debounce search
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (_controller.text == value) {
                          searchProvider.search(value);
                        }
                      });
                    },
                    onSubmitted: (value) {
                      searchProvider.search(value);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Case sensitive toggle
                IconButton(
                  icon: Icon(
                    Icons.text_fields,
                    size: 20,
                    color: state.caseSensitive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: 'Case sensitive',
                  onPressed: searchProvider.toggleCaseSensitive,
                ),

                // Match counter
                if (state.hasResults)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.currentMatchIndex + 1}/${state.totalMatches}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),

                // Navigation buttons
                if (state.hasResults) ...[
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    tooltip: 'Previous',
                    onPressed: searchProvider.previousMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    tooltip: 'Next',
                    onPressed: searchProvider.nextMatch,
                  ),
                ],

                // Loading indicator
                if (state.isSearching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close search',
                  onPressed: () {
                    searchProvider.clearSearch();
                    widget.onClose?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
