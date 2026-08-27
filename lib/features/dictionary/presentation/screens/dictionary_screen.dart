import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/features/dictionary/data/dictionary_service.dart';
import 'package:soundme_frontend/features/options/domain/models/translation_item.dart';
import 'package:soundme_frontend/features/options/presentation/screens/translation_list_screen.dart';

class DictionaryScreen extends ConsumerWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signsAsyncValue = ref.watch(allSignsProvider);

    return signsAsyncValue.when(
      data: (signs) {
        // Map API response to TranslationItem
        final items = signs.map((sign) {
          final id = sign['id']?.toString() ?? UniqueKey().toString();
          final text = sign['sign_name'] ?? 'Sin nombre';
          // Assume image URL is returned, or fallback to empty
          final imageUrl = sign['image_url'] ?? sign['url'] ?? '';

          return TranslationItem(
            id: id,
            text: text,
            imageUrl: imageUrl,
          );
        }).toList();

        return TranslationListScreen(
          title: 'Diccionario Completo',
          items: items,
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Diccionario'),
        ),
        body: Center(
          child: Text('Error al cargar el diccionario: $error'),
        ),
      ),
    );
  }
}
