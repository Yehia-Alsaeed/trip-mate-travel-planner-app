class Country {
  final String nameCommon;
  final String nameOfficial;
  final List<String> capital;
  final String region;
  final String subregion;
  final int population;
  final Map<String, String> languages; // language code -> language name
  final Map<String, CurrencyInfo> currencies; // currency code -> CurrencyInfo
  final String flagPng;
  final String googleMapsUrl;
  final List<String> borders; // ISO3 country codes
  final String? cca2; // ISO2 code
  final String? cca3; // ISO3 code
  final bool independent; // Whether country is independent
  final bool unMember; // Whether country is a UN member

  Country({
    required this.nameCommon,
    required this.nameOfficial,
    required this.capital,
    required this.region,
    required this.subregion,
    required this.population,
    required this.languages,
    required this.currencies,
    required this.flagPng,
    required this.googleMapsUrl,
    required this.borders,
    this.cca2,
    this.cca3,
    required this.independent,
    required this.unMember,
  });

  // Helper getters
  String get capitalText {
    if (capital.isEmpty) return 'N/A';
    return capital.join(', ');
  }

  String get languagesText {
    if (languages.isEmpty) return 'N/A';
    return languages.values.join(', ');
  }

  String get currenciesText {
    if (currencies.isEmpty) return 'N/A';
    return currencies.entries
        .map((e) {
          final code = e.key;
          final info = e.value;
          if (info.symbol.isNotEmpty) {
            return '$code (${info.symbol})';
          }
          return '$code (${info.name})';
        })
        .join(', ');
  }

  String get formattedPopulation {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}K';
    }
    return population.toString();
  }

  // Convert from JSON (null-safe)
  factory Country.fromJson(Map<String, dynamic> json) {
    // Name
    final name = json['name'] as Map<String, dynamic>? ?? {};
    final nameCommon = name['common'] as String? ?? 'Unknown';
    final nameOfficial = name['official'] as String? ?? 'Unknown';

    // Capital
    final capitalList = json['capital'] as List<dynamic>?;
    final capital = capitalList?.map((e) => e.toString()).toList() ?? [];

    // Region and subregion
    final region = json['region'] as String? ?? 'Unknown';
    final subregion = json['subregion'] as String? ?? 'Unknown';

    // Population
    final population = (json['population'] as num?)?.toInt() ?? 0;

    // Languages
    final languagesJson = json['languages'] as Map<String, dynamic>? ?? {};
    final languages = <String, String>{};
    languagesJson.forEach((key, value) {
      languages[key] = value.toString();
    });

    // Currencies
    final currenciesJson = json['currencies'] as Map<String, dynamic>? ?? {};
    final currencies = <String, CurrencyInfo>{};
    currenciesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        currencies[key] = CurrencyInfo(
          name: value['name']?.toString() ?? key,
          symbol: value['symbol']?.toString() ?? '',
        );
      }
    });

    // Flag
    final flags = json['flags'] as Map<String, dynamic>? ?? {};
    final flagPng = flags['png'] as String? ?? '';

    // Google Maps URL
    final maps = json['maps'] as Map<String, dynamic>? ?? {};
    final googleMapsUrl = maps['googleMaps'] as String? ?? '';

    // Borders (ISO3 codes)
    final bordersList = json['borders'] as List<dynamic>?;
    final borders = bordersList?.map((e) => e.toString()).toList() ?? [];

    // Country codes
    final cca2 = json['cca2'] as String?;
    final cca3 = json['cca3'] as String?;

    // Independent and UN member status
    final independent = json['independent'] as bool? ?? false;
    final unMember = json['unMember'] as bool? ?? false;

    return Country(
      nameCommon: nameCommon,
      nameOfficial: nameOfficial,
      capital: capital,
      region: region,
      subregion: subregion,
      population: population,
      languages: languages,
      currencies: currencies,
      flagPng: flagPng,
      googleMapsUrl: googleMapsUrl,
      borders: borders,
      cca2: cca2,
      cca3: cca3,
      independent: independent,
      unMember: unMember,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'nameCommon': nameCommon,
      'nameOfficial': nameOfficial,
      'capital': capital,
      'region': region,
      'subregion': subregion,
      'population': population,
      'languages': languages,
      'currencies': currencies.map((k, v) => MapEntry(k, v.toMap())),
      'flagPng': flagPng,
      'googleMapsUrl': googleMapsUrl,
      'borders': borders,
      'cca2': cca2,
      'cca3': cca3,
      'independent': independent,
      'unMember': unMember,
    };
  }

  // Create a copy with updated fields
  Country copyWith({
    String? nameCommon,
    String? nameOfficial,
    List<String>? capital,
    String? region,
    String? subregion,
    int? population,
    Map<String, String>? languages,
    Map<String, CurrencyInfo>? currencies,
    String? flagPng,
    String? googleMapsUrl,
    List<String>? borders,
    String? cca2,
    String? cca3,
    bool? independent,
    bool? unMember,
  }) {
    return Country(
      nameCommon: nameCommon ?? this.nameCommon,
      nameOfficial: nameOfficial ?? this.nameOfficial,
      capital: capital ?? this.capital,
      region: region ?? this.region,
      subregion: subregion ?? this.subregion,
      population: population ?? this.population,
      languages: languages ?? this.languages,
      currencies: currencies ?? this.currencies,
      flagPng: flagPng ?? this.flagPng,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      borders: borders ?? this.borders,
      cca2: cca2 ?? this.cca2,
      cca3: cca3 ?? this.cca3,
      independent: independent ?? this.independent,
      unMember: unMember ?? this.unMember,
    );
  }
}

class CurrencyInfo {
  final String name;
  final String symbol;

  CurrencyInfo({required this.name, required this.symbol});

  Map<String, dynamic> toMap() {
    return {'name': name, 'symbol': symbol};
  }
}
