import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatrixSignImage and SignImage tests', () {
    testWidgets('MatrixSignImage renders with coordinates and OverflowBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixSignImage(
              matrixAsset: 'assets/matrices/matriz_a_01.webp',
              coordinates: Rect.fromLTWH(200, 0, 200, 200),
              width: 150,
              height: 150,
            ),
          ),
        ),
      );

      expect(find.byType(MatrixSignImage), findsOneWidget);
      expect(find.byType(ClipRect), findsWidgets);
      expect(find.byType(OverflowBox), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('SignImage delegates to MatrixSignImage when sign has matrix coordinates', (tester) async {
      const matrixSign = MockSignEntry(
        id: 1,
        palabra: 'HOLA',
        descripcion: 'Saludo',
        gesto: 'Movimiento de mano',
        imagenAsset: '',
        seccion: 'H',
        infoAdicional: 'Interjección',
        archivoMatriz: 'matriz_h_01.webp',
        coordenadas: Rect.fromLTWH(0, 0, 200, 200),
        gestoFacial: 'Sonrisa',
        categoria: 'General',
      );

      expect(matrixSign.isMatrixSign, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignImage(
              sign: matrixSign,
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(MatrixSignImage), findsOneWidget);
    });

    testWidgets('SignImage delegates to Image.asset when sign is legacy (no matrix)', (tester) async {
      const legacySign = MockSignEntry(
        id: 2,
        palabra: 'ADIOS',
        descripcion: 'Despedida',
        gesto: 'Mover mano',
        imagenAsset: 'assets/images/mockup/senia_0001.png',
        seccion: 'A',
        infoAdicional: 'Interjección',
      );

      expect(legacySign.isMatrixSign, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignImage(
              sign: legacySign,
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(MatrixSignImage), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
