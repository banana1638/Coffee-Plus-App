import 'category_model.dart';
import 'transaction_model.dart';
import 'user_model.dart';

class DashboardViewModel {
  final Map<String, dynamic> rawData;
  final User user;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<String> allCategoryNames;
  final Map<String, dynamic>? options;

  const DashboardViewModel({
    required this.rawData,
    required this.user,
    required this.categories,
    required this.transactions,
    required this.allCategoryNames,
    required this.options,
  });

  factory DashboardViewModel.fromResponse(Map<String, dynamic> data) {
    final menusJson = data['menus'] as List? ?? const [];
    final transactionsJson = data['transactions'] as List? ?? const [];

    return DashboardViewModel(
      rawData: data,
      user: User.fromJson(data['user'] as Map<String, dynamic>? ?? const {}),
      categories: menusJson.map((json) => Category.fromJson(json)).toList(),
      transactions: transactionsJson
          .map((json) => Transaction.fromJson(json))
          .toList(),
      allCategoryNames: List<String>.from(data['allCategoryNames'] ?? const []),
      options: data['options'] is Map
          ? Map<String, dynamic>.from(data['options'] as Map)
          : null,
    );
  }

  bool get isGuest => user.isGuest;

  Transaction? get activeOrder {
    if (transactions.isEmpty || transactions.first.type != 'usage') {
      return null;
    }
    return transactions.first;
  }

  List<Category> visibleCategories({
    required String selectedCategory,
    required String searchQuery,
  }) {
    final normalizedCategory = selectedCategory.toLowerCase();
    final normalizedSearch = searchQuery.trim().toLowerCase();

    final filteredByCategory =
        selectedCategory == 'all' || selectedCategory == 'collections'
        ? categories
        : categories
              .where(
                (category) => category.name.toLowerCase() == normalizedCategory,
              )
              .toList(growable: false);

    if (normalizedSearch.isEmpty) {
      return filteredByCategory;
    }

    return filteredByCategory
        .map((category) {
          final products = category.products
              .where((product) {
                return product.name.toLowerCase().contains(normalizedSearch) ||
                    product.description.toLowerCase().contains(
                      normalizedSearch,
                    ) ||
                    category.name.toLowerCase().contains(normalizedSearch);
              })
              .toList(growable: false);

          return Category(
            id: category.id,
            name: category.name,
            products: products,
            productCount: products.length,
          );
        })
        .where((category) => category.products.isNotEmpty)
        .toList(growable: false);
  }
}
