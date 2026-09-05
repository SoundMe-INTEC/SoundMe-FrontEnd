import 'package:soundme_frontend/data/local/mockup_data_service.dart';

class TranslationItem {
  final String id;
  final String text;
  final String imageUrl;
  final MockSignEntry? sign;

  const TranslationItem({
    required this.id,
    required this.text,
    required this.imageUrl,
    this.sign,
  });
}