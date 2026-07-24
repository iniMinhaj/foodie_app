class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String? ?? '',
    );
  }
}
