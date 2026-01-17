import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/features/bookmarks/models/bookmark.dart';
import 'package:speed_reader/features/bookmarks/providers/bookmark_provider.dart';

class BookmarksDrawerWidget extends StatelessWidget {
  final String documentId;
  final Function(int) onJumpToPage;

  const BookmarksDrawerWidget({
    super.key,
    required this.documentId,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmarks, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Bookmarks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<BookmarkProvider>(
              builder: (context, provider, child) {
                final state = provider.state;

                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.bookmarks.isEmpty) {
                  return const Center(child: Text('No bookmarks yet'));
                }

                // Sort bookmarks by page number
                final sortedBookmarks = List<Bookmark>.from(state.bookmarks)
                  ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: sortedBookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = sortedBookmarks[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${bookmark.pageNumber}'),
                      ),
                      title: Text(
                        bookmark.note != null && bookmark.note!.isNotEmpty
                            ? bookmark.note!
                            : 'Page ${bookmark.pageNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Added on ${_formatDate(bookmark.createdAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, size: 20),
                            onPressed: () =>
                                _showNoteDialog(context, provider, bookmark),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => provider.toggleBookmark(
                              documentId,
                              bookmark.pageNumber,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        onJumpToPage(bookmark.pageNumber);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNoteDialog(
    BuildContext context,
    BookmarkProvider provider,
    Bookmark bookmark,
  ) {
    final controller = TextEditingController(text: bookmark.note);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note - Page ${bookmark.pageNumber}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add a note to this bookmark...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.updateNote(
                bookmark.documentId,
                bookmark.id,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
