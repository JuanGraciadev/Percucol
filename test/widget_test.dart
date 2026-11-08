import 'package:flutter_test/flutter_test.dart';
import 'package:percucol/models/product_model.dart';
import 'package:percucol/models/user_model.dart';
import 'package:percucol/models/category_model.dart';

void main() {
  group('Percucol Unit Tests', () {
    test('UserModel serialization and role checks', () {
      final admin = UserModel(
        id: 1,
        name: 'Admin User',
        email: 'admin@percucol.com',
        password: 'password',
        phone: '12345678',
        address: 'Calle 1',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isClient, isFalse);

      final map = admin.toMap();
      final fromMapUser = UserModel.fromMap(map);
      expect(fromMapUser.email, 'admin@percucol.com');
      expect(fromMapUser.role, 'admin');
    });

    test('CategoryModel serialization', () {
      const category = CategoryModel(
        id: 1,
        name: 'Baterías',
        description: 'Kits y tambores',
        iconName: 'drum',
        colorHex: '0xFFD4881A',
      );

      final map = category.toMap();
      final restored = CategoryModel.fromMap(map);
      expect(restored.name, 'Baterías');
    });

    test('ProductModel stock logic', () {
      const inStockProd = ProductModel(
        id: 1,
        name: 'Congas',
        description: 'Madera de roble',
        price: 3500000.0,
        stock: 5,
        categoryId: 1,
      );
      expect(inStockProd.hasStock, isTrue);
      expect(inStockProd.isOutOfStock, isFalse);

      const outOfStockProd = ProductModel(
        id: 2,
        name: 'Tambora Agotada',
        description: 'Ceiba',
        price: 520000.0,
        stock: 0,
        categoryId: 2,
      );
      expect(outOfStockProd.isOutOfStock, isTrue);
      expect(outOfStockProd.hasStock, isFalse);
    });
  });
}
