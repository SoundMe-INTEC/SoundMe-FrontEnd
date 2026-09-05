import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/network/api_endpoints.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/two_step_auth_screen.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';
import 'package:soundme_frontend/integration/network/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class MockInterceptor extends Interceptor {
  Response Function(RequestOptions options)? handler;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (this.handler != null) {
      try {
        final res = this.handler!(options);
        handler.resolve(res);
      } on DioException catch (e) {
        handler.reject(e);
      }
    } else {
      handler.next(options);
    }
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://127.0.0.1:8000/api');
  });

  late DioApiClient apiClient;
  late FakeTokenStorage tokenStorage;
  late MockInterceptor mockInterceptor;
  late AuthService authService;

  setUp(() {
    DioApiClient.resetInstance();
    mockInterceptor = MockInterceptor();
    apiClient = DioApiClient.create(interceptors: [mockInterceptor]);
    tokenStorage = FakeTokenStorage();
    authService = AuthService(apiClient: apiClient, tokenStorage: tokenStorage);
  });

  group('AuthService - checkCredentials', () {
    test('returns true when user requires OTP', () async {
      mockInterceptor.handler = (options) {
        expect(options.path, ApiEndpoints.check);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'user': '12345',
            'requires_otp': true,
            'message': 'OTP sent to your email.',
          },
        );
      };

      final result = await authService.checkCredentials('12345', 'pass123');
      expect(result, isTrue);
    });

    test('returns false when user is already active', () async {
      mockInterceptor.handler = (options) {
        expect(options.path, ApiEndpoints.check);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'user': '12345',
            'requires_otp': false,
            'message': 'Credentials verified.',
          },
        );
      };

      final result = await authService.checkCredentials('12345', 'pass123');
      expect(result, isFalse);
    });

    test('throws translated error on invalid credentials', () async {
      mockInterceptor.handler = (options) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'Invalid credentials'},
          ),
        );
      };

      expect(
        () => authService.checkCredentials('12345', 'wrongpass'),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('Credenciales inválidas'),
          ),
        ),
      );
    });

    test('throws mail relay 503 error message when delivery fails', () async {
      mockInterceptor.handler = (options) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            data: {'message': 'No se pudo enviar el código. Intenta de nuevo más tarde.'},
          ),
        );
      };

      expect(
        () => authService.checkCredentials('12345', 'pass'),
        throwsA(
          predicate(
            (e) => e.toString().contains('No se pudo enviar el código'),
          ),
        ),
      );
    });
  });

  group('AuthService - login with OTP', () {
    test('saves tokens when login with OTP succeeds', () async {
      mockInterceptor.handler = (options) {
        expect(options.path, ApiEndpoints.login);
        expect(options.data['otp'], '123456');
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'user': '12345',
            'access': 'access-token-xyz',
            'refresh': 'refresh-token-abc',
          },
        );
      };

      final success = await authService.login('12345', 'pass', otp: '123456');
      expect(success, isTrue);
      expect(tokenStorage.accessToken, 'access-token-xyz');
      expect(tokenStorage.refreshToken, 'refresh-token-abc');
    });

    test('throws specific error when OTP is invalid or expired', () async {
      mockInterceptor.handler = (options) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'Invalid or expired OTP'},
          ),
        );
      };

      expect(
        () => authService.login('12345', 'pass', otp: '999999'),
        throwsA(
          predicate(
            (e) => e.toString().contains('código OTP es inválido o ha expirado'),
          ),
        ),
      );
    });
  });

  group('AuthService - verifyOtp', () {
    test('returns true when verify-otp succeeds', () async {
      mockInterceptor.handler = (options) {
        expect(options.path, ApiEndpoints.verifyOtp);
        expect(options.data['identification'], '12345');
        expect(options.data['otp'], '654321');
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'user': '12345', 'message': 'OTP verified successfully.'},
        );
      };

      final verified = await authService.verifyOtp('12345', '654321');
      expect(verified, isTrue);
    });

    test('throws error when user is already verified', () async {
      mockInterceptor.handler = (options) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'User is already verified'},
          ),
        );
      };

      expect(
        () => authService.verifyOtp('12345', '654321'),
        throwsA(
          predicate(
            (e) => e.toString().contains('ya ha sido verificado'),
          ),
        ),
      );
    });
  });

  group('TwoStepAuthScreen Widget Tests', () {
    testWidgets('renders 6 input boxes, title and resend button with countdown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: TwoStepAuthScreen(
              identification: '12345',
              password: 'password',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Verificar'), findsOneWidget);
      expect(find.textContaining('Reenviar en'), findsOneWidget);
      expect(find.textContaining('¿No recibiste el código?'), findsOneWidget);
    });

    testWidgets('entering 6 digits triggers verification call', (tester) async {
      String? submittedOtp;
      mockInterceptor.handler = (options) {
        if (options.path == ApiEndpoints.login) {
          submittedOtp = options.data['otp'];
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'user': '12345',
              'access': 'access-token',
              'refresh': 'refresh-token',
            },
          );
        }
        return Response(requestOptions: options, statusCode: 200);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: TwoStepAuthScreen(
              identification: '12345',
              password: 'password',
            ),
          ),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(submittedOtp, '123456');
    });

    testWidgets('LoginScreen navigates to TwoStepAuthScreen even when check returns requires_otp: false', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.75, 915 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockInterceptor.handler = (options) {
        if (options.path == ApiEndpoints.check) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'user': '12345',
              'requires_otp': false,
              'message': 'Credentials verified.',
            },
          );
        }
        return Response(requestOptions: options, statusCode: 200);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '12345');
      await tester.enterText(textFields.at(1), 'Password123!');
      await tester.pump();

      final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TwoStepAuthScreen), findsOneWidget);
    });
  });
}
