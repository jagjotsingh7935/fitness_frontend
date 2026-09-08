/// Category DTO representing categories fetched from `/accounts/api/category-list/`.
final class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.iconUrl,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? iconUrl;
  final String? description;
  final bool isActive;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      iconUrl: (json['icon_url'] ?? json['icon']) as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'description': description,
      'is_active': isActive,
    };
  }
}
