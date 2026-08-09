import '../../../../core/entities/category.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconUrl;

  const CategoryModel({required this.id, required this.name, required this.iconUrl});

  Category toEntity() => Category(id: id, name: name, iconUrl: iconUrl);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String? ?? '',
    );
  }
}
