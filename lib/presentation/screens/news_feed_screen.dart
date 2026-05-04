import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';
import '../../providers/api_providers.dart';

class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  final List<String> filters = [
    'All',
    'Race Results',
    'Technical',
    'Drivers',
    'Rumours'
  ];
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PITWALL',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: newsAsync.when(
              data: (news) => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: news.length,
                itemBuilder: (context, index) {
                  final article = news[index];
                  return _buildNewsCard(article);
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: PitwallTheme.primaryAccent),
              ),
              error: (err, stack) => Center(
                child: Text('News unavailable: $err', style: const TextStyle(color: Colors.white60)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedFilter = filter);
              },
              backgroundColor: PitwallTheme.cardBackground,
              selectedColor: PitwallTheme.primaryAccent,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: isSelected ? PitwallTheme.primaryAccent : PitwallTheme.cardBorder,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(dynamic article) {
    final String title = article['title'] ?? 'No Title';
    final String source = article['source'] ?? 'Unknown';
    final String timeAgo = article['publishedAt'] ?? '';
    final String? imageUrl = article['urlToImage'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PitwallCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: PitwallTheme.cardBackground,
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: PitwallTheme.primaryAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              source.toUpperCase(),
                              style: const TextStyle(
                                color: PitwallTheme.primaryAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                      const Icon(Icons.share_outlined, size: 18, color: Colors.white60),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
