import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/features/options/domain/models/translation_item.dart';

class TranslationListScreen extends StatefulWidget {
  final String title;
  final List<TranslationItem> items;

  const TranslationListScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<TranslationListScreen> createState() => _TranslationListScreenState();
}

class _TranslationListScreenState extends State<TranslationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TranslationItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  String _normalize(String input) {
    var text = input.trim().toUpperCase();
    text = text.replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A');
    text = text.replaceAll(RegExp(r'[ÉÈËÊ]'), 'E');
    text = text.replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I');
    text = text.replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O');
    text = text.replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U');
    return text;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        final normalizedQuery = _normalize(query);
        _filteredItems = widget.items
            .where((item) => _normalize(item.text).contains(normalizedQuery))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: widget.title),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 65),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? const Center(
                      child: Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textGray,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _filteredItems.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        return _buildCard(_filteredItems[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 59,
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: _searchController,
          onChanged: _filterItems,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppColors.primaryNavy,
          ),
          decoration: const InputDecoration(
            hintText: 'Buscar...',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textGray,
            ),
            border: InputBorder.none,
            suffixIcon: Icon(
              Icons.search,
              color: AppColors.primaryNavy,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageModal(BuildContext context, TranslationItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.primaryNavy),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: item.sign != null
                    ? SignImage(sign: item.sign!, fit: BoxFit.contain)
                    : Image.asset(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.primaryNavy,
                              size: 60,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(TranslationItem item) {
    return GestureDetector(
      onTap: () => _showImageModal(context, item),
      child: Container(
        height: 118,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardFillColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const SizedBox(width: 9),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.sign != null
                ? SignImage(sign: item.sign!, fit: BoxFit.contain)
                : Image.asset(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.primaryNavy,
                          size: 32,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              item.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryNavy,
                height: 1.2,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(
              Icons.zoom_in,
              color: AppColors.primaryNavy,
              size: 24,
            ),
          ),
        ],
      ),
    ));
  }
}