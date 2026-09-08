import '../../../../core/utils/result.dart';
import '../../data/models/category_dto.dart';
import '../repositories/auth_repository.dart';

/// Application use case: get active categories for signup.
final class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<List<CategoryDto>>> call() {
    return _repository.fetchCategories();
  }
}
