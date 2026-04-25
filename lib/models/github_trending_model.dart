class BuiltByUser {
  final String username;
  final String avatar;

  const BuiltByUser({required this.username, required this.avatar});

  factory BuiltByUser.fromJson(Map<String, dynamic> json) => BuiltByUser(
        username: json['username'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
      );
}

class TrendingRepo {
  final String author;
  final String name;
  final String avatar;
  final String url;
  final String description;
  final String language;
  final String languageColor;
  final int stars;
  final int forks;
  final int currentPeriodStars;
  final List<BuiltByUser> builtBy;

  const TrendingRepo({
    required this.author,
    required this.name,
    required this.avatar,
    required this.url,
    required this.description,
    required this.language,
    required this.languageColor,
    required this.stars,
    required this.forks,
    required this.currentPeriodStars,
    required this.builtBy,
  });

  factory TrendingRepo.fromJson(Map<String, dynamic> json) => TrendingRepo(
        author: json['author'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        url: json['url'] as String? ?? '',
        description: json['description'] as String? ?? '',
        language: json['language'] as String? ?? '',
        languageColor: json['languageColor'] as String? ?? '#888888',
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        forks: (json['forks'] as num?)?.toInt() ?? 0,
        currentPeriodStars: (json['currentPeriodStars'] as num?)?.toInt() ?? 0,
        builtBy: (json['builtBy'] as List<dynamic>?)
                ?.map((e) => BuiltByUser.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TrendingDeveloperRepo {
  final String name;
  final String description;
  final String url;

  const TrendingDeveloperRepo({
    required this.name,
    required this.description,
    required this.url,
  });

  factory TrendingDeveloperRepo.fromJson(Map<String, dynamic> json) =>
      TrendingDeveloperRepo(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

class TrendingDeveloper {
  final String username;
  final String name;
  final String type;
  final String url;
  final String avatar;
  final TrendingDeveloperRepo? repo;

  const TrendingDeveloper({
    required this.username,
    required this.name,
    required this.type,
    required this.url,
    required this.avatar,
    this.repo,
  });

  factory TrendingDeveloper.fromJson(Map<String, dynamic> json) =>
      TrendingDeveloper(
        username: json['username'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'User',
        url: json['url'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        repo: json['repo'] != null
            ? TrendingDeveloperRepo.fromJson(
                json['repo'] as Map<String, dynamic>)
            : null,
      );
}
