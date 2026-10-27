import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/categories/data/repositories/category_repository.dart';
import 'package:birrmetrics/features/categories/domain/entities/category.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoriesNotifier extends StateNotifier<AsyncValue<List<ExpenseCategory>>> {
  final CategoryRepository _repo;

  CategoriesNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAllCategories());
  }

  Future<void> addCategory(String name, String icon) async {
    await _repo.addCategory(name, icon);
    await load();
  }

  Future<void> deleteCategory(int id) async {
    await _repo.deleteCategory(id);
    await load();
  }
}

final categoriesProvider =
StateNotifierProvider<CategoriesNotifier, AsyncValue<List<ExpenseCategory>>>((ref) {
  return CategoriesNotifier(ref.watch(categoryRepositoryProvider));
});
