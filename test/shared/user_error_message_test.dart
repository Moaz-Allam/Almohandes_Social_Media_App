import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow/data/repositories/repository_failure.dart';
import 'package:tradeflow/shared/errors/user_error_message.dart';

void main() {
  group('userErrorMessage', () {
    test('keeps repository failure messages', () {
      expect(
        userErrorMessage(
          const RepositoryFailure('Please try again later'),
          fallback: 'fallback',
        ),
        'Please try again later',
      );
    });

    test('hides raw database and policy errors', () {
      const fallback = 'fallback';

      expect(
        userErrorMessage(
          'new row violates row-level security policy for table profiles',
          fallback: fallback,
        ),
        fallback,
      );
      expect(
        userErrorMessage(
          'PostgREST SQLSTATE 42501 permission denied for schema public',
          fallback: fallback,
        ),
        fallback,
      );
      expect(
        userErrorMessage(Exception('Supabase failed'), fallback: fallback),
        fallback,
      );
    });

    test('allows short Arabic product messages', () {
      const message = '\u062a\u0645 \u0627\u0644\u062d\u0641\u0638';

      expect(userErrorMessage(message, fallback: 'fallback'), message);
    });
  });
}
