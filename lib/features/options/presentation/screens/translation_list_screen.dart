import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
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

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.text.toLowerCase().contains(query.toLowerCase()))
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
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Título Dinámico
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
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
              color: Color(0xFF747474),
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

  Widget _buildCard(TranslationItem item) {
    return Container(
      height: 115,
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
            child: Image.asset(
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
              Icons.arrow_forward_ios,
              color: AppColors.primaryNavy,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}