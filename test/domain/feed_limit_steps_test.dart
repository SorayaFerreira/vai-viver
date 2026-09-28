import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/feed_limit_steps.dart';

void main() {
  test('1-minute steps up to 5, then 5-minute steps', () {
    expect(nextFeedLimit(1), 2);
    expect(nextFeedLimit(4), 5);
    expect(nextFeedLimit(5), 10);
    expect(nextFeedLimit(20), 25);
  });

  test('going down mirrors going up and never drops below 1', () {
    expect(previousFeedLimit(25), 20);
    expect(previousFeedLimit(10), 5);
    expect(previousFeedLimit(5), 4);
    expect(previousFeedLimit(2), 1);
    expect(previousFeedLimit(1), 1);
  });
}
