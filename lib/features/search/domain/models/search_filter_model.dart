class SearchFilter {
  final String? category;
  final String? date;
  final String? price;
  final bool? isFreeOnly;
  final bool? isRegisteredOnly;
  final String? sortBy;
  final int? minSKKM; // ✅ Filter minimum SKKM
  final int? maxSKKM; // ✅ Filter maksimum SKKM

  SearchFilter({
    this.category,
    this.date,
    this.price,
    this.isFreeOnly,
    this.isRegisteredOnly,
    this.sortBy,
    this.minSKKM,
    this.maxSKKM,
  });

  SearchFilter copyWith({
    String? category,
    String? date,
    String? price,
    bool? isFreeOnly,
    bool? isRegisteredOnly,
    String? sortBy,
    int? minSKKM,
    int? maxSKKM,
  }) {
    return SearchFilter(
      category: category ?? this.category,
      date: date ?? this.date,
      price: price ?? this.price,
      isFreeOnly: isFreeOnly ?? this.isFreeOnly,
      isRegisteredOnly: isRegisteredOnly ?? this.isRegisteredOnly,
      sortBy: sortBy ?? this.sortBy,
      minSKKM: minSKKM ?? this.minSKKM,
      maxSKKM: maxSKKM ?? this.maxSKKM,
    );
  }

  bool get hasFilters {
    return category != null ||
        date != null ||
        price != null ||
        isFreeOnly == true ||
        isRegisteredOnly == true ||
        sortBy != null ||
        minSKKM != null ||
        maxSKKM != null;
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'date': date,
      'price': price,
      'isFreeOnly': isFreeOnly,
      'isRegisteredOnly': isRegisteredOnly,
      'sortBy': sortBy,
      'minSKKM': minSKKM,
      'maxSKKM': maxSKKM,
    };
  }
}
