class Article {
  final String title;
  final String source;
  final String publishedAt;
  final String? urlToImage;
  final String url;
  final bool isRead;

  Article({
    required this.title,
    required this.source,
    required this.publishedAt,
    this.urlToImage,
    required this.url,
    this.isRead = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      source: json['source'] ?? 'Unknown',
      publishedAt: json['publishedAt'] ?? '',
      urlToImage: json['urlToImage'],
      url: json['url'] ?? '',
    );
  }
}

class SessionResult {
  final int position;
  final String driverCode;
  final String fullName;
  final String teamName;
  final String teamColor;
  final String time;
  final double points;
  final String status;

  SessionResult({
    required this.position,
    required this.driverCode,
    required this.fullName,
    required this.teamName,
    required this.teamColor,
    required this.time,
    required this.points,
    required this.status,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      position: json['position'] ?? 0,
      driverCode: json['driver_code'] ?? '',
      fullName: json['full_name'] ?? '',
      teamName: json['team'] ?? '',
      teamColor: json['team_color'] ?? '#FFFFFF',
      time: json['time'] ?? '',
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
    );
  }
}

class RaceEvent {
  final int round;
  final String eventName;
  final String country;
  final String date;
  final String format;

  RaceEvent({
    required this.round,
    required this.eventName,
    required this.country,
    required this.date,
    required this.format,
  });

  factory RaceEvent.fromJson(Map<String, dynamic> json) {
    return RaceEvent(
      round: json['round_number'] ?? 0,
      eventName: json['event_name'] ?? '',
      country: json['country'] ?? '',
      date: json['date_race'] ?? '',
      format: json['event_format'] ?? 'conventional',
    );
  }
}
