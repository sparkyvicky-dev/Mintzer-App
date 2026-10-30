import 'package:flutter_test/flutter_test.dart';
import 'package:mintzer/util/shop_url.dart';

void main() {
  test('store pages on https are allowed', () {
    expect(
      classifyShopNavigation('https://www.flipkart.com/item'),
      ShopNavigation.allowPage,
    );
    expect(
      classifyShopNavigation('https://www.amazon.in/dp/abc'),
      ShopNavigation.allowPage,
    );
  });

  test('plain http and script links are blocked', () {
    expect(classifyShopNavigation('http://example.com'), ShopNavigation.block);
    expect(classifyShopNavigation('javascript:alert(1)'), ShopNavigation.block);
    expect(classifyShopNavigation('file:///sdcard/secret'), ShopNavigation.block);
    expect(classifyShopNavigation('not a url'), ShopNavigation.block);
  });

  test('upi and phone links leave the page', () {
    expect(classifyShopNavigation('upi://pay?pa=shop@upi'), ShopNavigation.openOutside);
    expect(classifyShopNavigation('tel:+919000000000'), ShopNavigation.openOutside);
  });
}
