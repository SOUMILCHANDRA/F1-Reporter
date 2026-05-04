import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';

class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  final List<String> filters = ['All', 'Race Results', 'Technical', 'Drivers', 'Rumours'];
  String selectedFilter = 'All';
  Set<String> readArticles = {};

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      readArticles = (prefs.getStringList('read_articles') ?? []).toSet();
    });
  }

  Future<void> _markAsRead(String url) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => readArticles.add(url));
    await prefs.setStringList('read_articles', readArticles.toList());
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: Text('PITWALL', style: AppConfig.displayStyle.copyWith(fontSize: 22, letterSpacing: 2)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(newsProvider(1).future),
              color: AppConfig.accentRed,
              child: newsAsync.when(
                data: (news) {
                  final filteredNews = news.where((a) {
                    if (selectedFilter == 'All') return true;
                    final title = a['title']?.toString().toLowerCase() ?? '';
                    return title.contains(selectedFilter.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNews.length,
                    itemBuilder: (context, index) {
                      final article = filteredNews[index];
                      final url = article['url'] ?? '';
                      final isRead = readArticles.contains(url);
                      
                      return _buildArticleCard(article, isRead);
                    },
                  );
                },
                loading: () => _buildShimmer(),
                error: (err, stack) => _buildErrorState(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
              label: Text(filter.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedFilter = filter),
              selectedColor: AppConfig.accentRed,
              backgroundColor: AppConfig.surface,
              showCheckmark: false,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppConfig.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(dynamic article, bool isRead) {
    return GestureDetector(
      onTap: () {
        _markAsRead(article['url']);
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => NewsWebView(url: article['url'], title: article['title']),
        ));
      },
      child: Opacity(
        opacity: isRead ? 0.6 : 1.0,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppConfig.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppConfig.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article['urlToImage'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    article['urlToImage'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppConfig.accentRed, borderRadius: BorderRadius.circular(2)),
                          child: Text(
                            (article['source'] ?? 'F1').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isRead) const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                        ),
                        const Spacer(),
                        Text(
                          article['publishedAt'] ?? '',
                          style: TextStyle(color: AppConfig.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['title'] ?? '',
                      style: AppConfig.bodyStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppConfig.card,
        highlightColor: AppConfig.border,
        child: Container(
          height: 240,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppConfig.accentRed),
          const SizedBox(height: 16),
          Text('COULD NOT FETCH NEWS', style: AppConfig.displayStyle.copyWith(fontSize: 14)),
          TextButton(onPressed: () => ref.refresh(newsProvider(1)), child: const Text('RETRY')),
        ],
      ),
    );
  }
}

class NewsWebView extends StatelessWidget {
  final String url;
  final String title;
  const NewsWebView({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 14))),
      body: WebViewWidget(controller: controller),
    );
  }
}
