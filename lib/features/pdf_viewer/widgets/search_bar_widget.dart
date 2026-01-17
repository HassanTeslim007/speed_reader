import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/widgets/glass_container.dart';
import 'package:speed_reader/features/pdf_viewer/providers/search_provider.dart';

class SearchBarWidget extends StatefulWidget {
  final VoidCallback? onClose;

  const SearchBarWidget({super.key, this.onClose});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: 20,
          opacity: theme.brightness == Brightness.dark ? 0.2 : 0.4,
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              final state = searchProvider.state;

              return Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search context...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        searchProvider.search(value);
                      },
                    ),
                  ),
                  if (state.hasResults) ...[
                    Text(
                      '${state.currentMatchIndex + 1}/${state.totalMatches}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SearchNavButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: searchProvider.previousMatch,
                    ),
                    _SearchNavButton(
                      icon: Icons.keyboard_arrow_down,
                      onPressed: searchProvider.nextMatch,
                    ),
                  ],
                  if (state.isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      searchProvider.clearSearch();
                      widget.onClose?.call();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SearchNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(),
    );
  }
}
