import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabcargo/admin/widgets/role_guard.dart';
import 'package:sabcargo/core/widgets/sabcargo_button.dart';
import 'package:sabcargo/services/local_registration_store.dart';

void main() {
  testWidgets('RoleGate blocks admin route for normal users', (tester) async {
    SharedPreferences.setMockInitialValues({
      'sabcargo_user_role': 'User',
    });

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/admin',
        routes: {
          '/home': (_) => const Scaffold(body: Text('HOME')),
          '/admin': (_) => const RoleGate(
                allowedRoles: ['Admin', 'SuperAdmin'],
                child: Scaffold(body: Text('ADMIN')),
              ),
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('ADMIN'), findsNothing);
  });

  testWidgets('RoleGate allows admin route for Admin role', (tester) async {
    SharedPreferences.setMockInitialValues({
      'sabcargo_user_role': 'Admin',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const RoleGate(
          allowedRoles: ['Admin', 'SuperAdmin'],
          child: Scaffold(body: Text('ADMIN')),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('ADMIN'), findsOneWidget);
  });

  test('registration data is saved in local json store', () async {
    SharedPreferences.setMockInitialValues({});

    // Directly write one registration record to avoid network calls during unit tests.
    await LocalRegistrationStore.saveRegistration(
      name: 'Test User',
      email: 'test@example.com',
      phone: '+123456789',
      pin: '123456',
    );

    final rows = await LocalRegistrationStore.getAllRegistrations();
    expect(rows.isNotEmpty, isTrue);
    expect(rows.last['name'], 'Test User');
    expect(rows.last['email'], 'test@example.com');
    expect(rows.last['phone'], '+123456789');
    expect((rows.last['pin'] ?? '').toString().length, 6);
  });

  testWidgets('SabCargoButton renders all variants without assertion error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SabCargoButton(text: 'Primary', onPressed: () {}),
              SabCargoButton.secondary(text: 'Secondary', onPressed: () {}),
              SabCargoButton.outline(text: 'Outline', onPressed: () {}),
              SabCargoButton.danger(text: 'Danger', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Outline'), findsOneWidget);
    expect(find.text('Danger'), findsOneWidget);
  });
}
