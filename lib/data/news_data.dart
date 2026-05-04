class NewsArticle {
  final String title;
  final String source;
  final String timeAgo;
  final String imageUrl;
  final List<String> tags;
  final bool isRead;

  NewsArticle({
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.imageUrl,
    required this.tags,
    this.isRead = false,
  });
}

final mockNews = [
  NewsArticle(
    title: "Ferrari's new floor upgrade adds 0.2s performance",
    source: "Technical Analysis",
    timeAgo: "2h ago",
    imageUrl: "https://images.unsplash.com/photo-1594738401344-96426463945a?auto=format&fit=crop&q=80&w=800",
    tags: ["Technical", "Ferrari"],
  ),
  NewsArticle(
    title: "Verstappen targets record-breaking 10th consecutive win",
    source: "Race Preview",
    timeAgo: "4h ago",
    imageUrl: "https://images.unsplash.com/photo-1594738401344-96426463945a?auto=format&fit=crop&q=80&w=800",
    tags: ["Drivers", "Red Bull"],
  ),
  NewsArticle(
    title: "New 2026 Engine Regulations: What we know so far",
    source: "F1 Insider",
    timeAgo: "6h ago",
    imageUrl: "https://images.unsplash.com/photo-1594738401344-96426463945a?auto=format&fit=crop&q=80&w=800",
    tags: ["Technical", "Regulations"],
    isRead: true,
  ),
];
