import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:coffee_plus_app/core/error_handler.dart';
import 'package:coffee_plus_app/models/cart_item_model.dart';
import 'package:coffee_plus_app/models/category_model.dart';
import 'package:coffee_plus_app/models/favorite_model.dart';
import 'package:coffee_plus_app/models/product_model.dart';
import 'package:coffee_plus_app/models/transaction_model.dart';
import 'package:coffee_plus_app/models/user_model.dart';
import 'package:coffee_plus_app/models/device_token_model.dart';
import 'package:coffee_plus_app/services/device_name_provider.dart';
import 'package:coffee_plus_app/services/payment_service.dart';

void main() {
  group('User.fromJson', () {
    test('returns guest defaults for null payload', () {
      final user = User.fromJson(null);

      expect(user.id, isNull);
      expect(user.name, 'GUEST');
      expect(user.email, '');
      expect(user.balance, 0);
      expect(user.oz, 0);
    });

    test('parses numeric strings safely', () {
      final user = User.fromJson({
        'id': '42',
        'name': 'Aina',
        'email': 'aina@example.com',
        'balance': '12.50',
        'oz': '300',
      });

      expect(user.id, '42');
      expect(user.balance, 12.5);
      expect(user.oz, 300);
    });
  });

  group('Product.fromJson', () {
    test('parses price, availability, options, and addons', () {
      final product = Product.fromJson({
        'id': 7,
        'name': 'Latte',
        'description': 'Milk coffee',
        'image_url': 'latte.png',
        'base_price': '9.90',
        'is_available': '1',
        'options': {
          'sizes': ['Regular'],
        },
        'addons': [
          {'id': 1, 'name': 'Shot', 'price': '1.50'},
        ],
      });

      expect(product.id, 7);
      expect(product.price, 9.9);
      expect(product.isAvailable, isTrue);
      expect(product.options, isNotNull);
      expect(product.addons, hasLength(1));
      expect(product.addons!.single.price, 1.5);
    });
  });

  group('Category.fromJson', () {
    test('parses iterable products', () {
      final category = Category.fromJson({
        'category_id': 3,
        'category_name': 'Coffee',
        'product_count': 1,
        'products': [
          {'id': 1, 'name': 'Americano', 'base_price': 6},
        ],
      });

      expect(category.id, 3);
      expect(category.name, 'Coffee');
      expect(category.productCount, 1);
      expect(category.products.single.name, 'Americano');
    });
  });

  group('CartItem.fromJson', () {
    test('parses nested product and calculates oz needed', () {
      final item = CartItem.fromJson({
        'id': '9',
        'quantity': '2',
        'size': 'Large',
        'temp': 'Iced',
        'addons': ['Shot'],
        'unit_price': '8.50',
        'total_item_price': '17.25',
        'product': {'id': 4, 'name': 'Mocha', 'base_price': '8.50'},
      });

      expect(item.id, 9);
      expect(item.quantity, 2);
      expect(item.product.name, 'Mocha');
      expect(item.ozNeeded, 1725);
    });
  });

  group('FavoriteItem', () {
    test('round trips to json and preserves unique selection id', () {
      final product = Product.fromJson({
        'id': 5,
        'name': 'Flat White',
        'base_price': 11,
      });
      final favorite = FavoriteItem(
        id: 10,
        product: product,
        size: 'Regular',
        temp: 'Hot',
        addons: ['Oat Milk'],
        remark: 'Morning',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final parsed = FavoriteItem.fromJson(favorite.toJson());

      expect(parsed.id, 10);
      expect(parsed.product.name, 'Flat White');
      expect(parsed.uniqueId, '5_Regular_Hot_Oat Milk');
    });
  });

  group('Transaction.fromJson', () {
    test('keeps raw payload for order detail screens', () {
      final json = {
        'id': '12',
        'bill_id': 'BILL-1',
        'type': 'usage',
        'oz_delta': '-200',
        'description': 'Order paid',
        'time': '10:00',
        'order_details': {'status': 'completed'},
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 12);
      expect(transaction.billId, 'BILL-1');
      expect(transaction.rawJson, same(json));
    });
  });

  group('ErrorHandler', () {
    DioException responseError(int statusCode, dynamic data) {
      return DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: statusCode,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    test('surfaces validation field errors', () {
      final message = ErrorHandler.toUserMessage(
        responseError(422, {
          'errors': {
            'size': ['The selected size is invalid.'],
          },
        }),
      );

      expect(message, 'The selected size is invalid.');
    });

    test('maps conflict and rate limit responses', () {
      expect(
        ErrorHandler.toUserMessage(
          responseError(409, {'message': 'Payload changed for this key.'}),
        ),
        'Payload changed for this key.',
      );
      expect(
        ErrorHandler.toUserMessage(responseError(429, {})),
        'Too many requests. Please wait before retrying.',
      );
    });

    test('prefers standardized server messages for auth and not found', () {
      expect(
        ErrorHandler.toUserMessage(
          responseError(401, {
            'status': 'error',
            'message': 'Unauthenticated.',
          }),
        ),
        'Unauthenticated.',
      );
      expect(
        ErrorHandler.toUserMessage(
          responseError(404, {'status': 'error', 'message': 'Not found.'}),
        ),
        'Not found.',
      );
    });
  });

  group('PaymentService', () {
    test('extracts Stripe session id from response data or redirect url', () {
      expect(
        PaymentService.extractSessionId({
          'data': {'session_id': 'cs_test_nested'},
        }, 'https://checkout.stripe.com/c/pay/cs_test_url'),
        'cs_test_nested',
      );
      expect(
        PaymentService.extractSessionId(
          {},
          'https://checkout.stripe.com/c/pay/cs_test_url#fidkdWxOYHwn',
        ),
        'cs_test_url',
      );
    });

    test('only treats processed status as confirmed', () {
      const processed = PaymentStatusSnapshot(
        sessionId: 'cs_processed',
        status: 'processed',
        rawData: {},
      );
      const failed = PaymentStatusSnapshot(
        sessionId: 'cs_failed',
        status: 'failed',
        rawData: {},
      );

      expect(processed.isProcessed, isTrue);
      expect(failed.isProcessed, isFalse);
    });
  });

  group('Device token management', () {
    test('parses current device metadata without a token secret', () {
      final token = DeviceToken.fromJson({
        'id': 12,
        'device_name': 'Android - Coffee Phone',
        'is_current': true,
        'last_used_at': '2026-06-28T10:00:00Z',
      });

      expect(token.id, '12');
      expect(token.name, 'Android - Coffee Phone');
      expect(token.isCurrent, isTrue);
      expect(token.lastUsedAt, isNotNull);
    });

    test('normalizes device names to the backend length limit', () {
      final name = DeviceNameProvider.normalize(
        operatingSystem: 'android',
        hostName: List.filled(150, 'A').join(),
      );

      expect(name, startsWith('Android - '));
      expect(name.length, 100);
      expect(
        DeviceNameProvider.normalize(
          operatingSystem: 'ios',
          hostName: 'localhost',
        ),
        'iOS device',
      );
    });
  });
}
