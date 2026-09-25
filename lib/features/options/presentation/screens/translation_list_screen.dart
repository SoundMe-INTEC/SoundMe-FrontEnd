import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
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
  final Set<String> _expandedItemIds = <String>{};

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedItemIds.contains(id)) {
        _expandedItemIds.remove(id);
      } else {
        _expandedItemIds.add(id);
      }
    });
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
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

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
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron resultados',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredItems.length,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemBuilder: (context, index) {
                                return _buildCard(_filteredItems[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: _searchController,
          onChanged: _filterItems,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar en la lista...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryNavy,
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 26,
              minHeight: 26,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterItems('');
                    },
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 26,
              minHeight: 26,
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorderColor),
            boxShadow: AppColors.cardShadow,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.primaryNavy,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (item.sign != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SignImage(sign: item.sign!, fit: BoxFit.contain),
                )
              else if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
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
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.primaryNavy,
                    size: 64,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(TranslationItem item) {
    final hasPreview = item.sign != null || item.imageUrl.isNotEmpty;
    final isExpanded = _expandedItemIds.contains(item.id);

    return GestureDetector(
      onTap: item.signsInOrder.isNotEmpty
          ? () => _toggleExpanded(item.id)
          : (hasPreview ? () => _showImageModal(context, item) : null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardFillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.sign != null
                  ? SignImage(sign: item.sign!, fit: BoxFit.contain)
                  : item.imageUrl.isNotEmpty
                  ? Image.asset(
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
                    )
                  : const Center(
                      child: Icon(
                        Icons.history_rounded,
                        color: AppColors.primaryNavy,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                      height: 1.2,
                    ),
                  ),
                  if (item.signsInOrder.isNotEmpty && isExpanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.signsInOrder
                          .map(
                            (sign) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.cardBorderColor,
                                ),
                              ),
                              child: Text(
                                sign,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Icon(
                item.signsInOrder.isNotEmpty
                    ? (isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded)
                    : (hasPreview
                          ? Icons.zoom_in_rounded
                          : Icons.chevron_right_rounded),
                color: AppColors.primaryNavy,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
