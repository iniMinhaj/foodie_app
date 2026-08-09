import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('only the last call within the delay window fires', () {
      fakeAsync((async) {
        final debouncer = Debouncer(const Duration(milliseconds: 400));
        var callCount = 0;

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 200));
        debouncer.run(() => callCount++); // cancels the pending call above
        async.elapse(const Duration(milliseconds: 200));

        expect(callCount, 0); // still within the new 400ms window

        async.elapse(const Duration(milliseconds: 200));

        expect(callCount, 1);
      });
    });

    test('dispose cancels a pending call', () {
      fakeAsync((async) {
        final debouncer = Debouncer(const Duration(milliseconds: 400));
        var callCount = 0;

        debouncer.run(() => callCount++);
        debouncer.dispose();
        async.elapse(const Duration(milliseconds: 500));

        expect(callCount, 0);
      });
    });
  });
}
