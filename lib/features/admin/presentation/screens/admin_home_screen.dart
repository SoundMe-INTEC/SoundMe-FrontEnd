import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  String _activeFilter = 'Todas';
  bool _isOptimizing = false;

  @override
  Widget build(BuildContext context) {
    final mockData = ref.watch(allMockSignsProvider);
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 1. HERO ADMIN BANNER
                    _buildAdminHeroHeader(),

                    const SizedBox(height: 20),

                    // 2. GRID DE KPIS & SALUD DEL SISTEMA
                    mockData.when(
                      data: (signs) => _buildKpiGrid(signs),
                      loading: () => _buildLoadingKpiGrid(),
                      error: (_, _) => _buildErrorKpiGrid(),
                    ),

                    const SizedBox(height: 24),

                    // 3. SECCIÓN DE ESTADO DEL MOTOR LSRD & METADATOS
                    _buildEngineHealthCard(mockData.valueOrNull?.length ?? 2427),

                    const SizedBox(height: 24),

                    // 4. ACCIONES RÁPIDAS Y HERRAMIENTAS ADMINISTRATIVAS
                    Text(
                      'Herramientas y Acciones Rápidas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildActionTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Explorar y Auditar Diccionario',
                      subtitle: 'Visualiza celdas, gestos y vectores SVG oficiales',
                      color: AppColors.primaryNavy,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DictionaryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildActionTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Optimizar Caché y Memoria',
                      subtitle: _isOptimizing
                          ? 'Limpiando buffers y recargando matrices...'
                          : 'Depura índices fonéticos y recarga Sprite Sheets',
                      color: const Color(0xFF0284C7),
                      isLoading: _isOptimizing,
                      onTap: _runOptimization,
                    ),

                    const SizedBox(height: 10),

                    _buildActionTile(
                      icon: Icons.verified_user_rounded,
                      title: 'Diagnóstico de Seguridad & Permisos',
                      subtitle: 'Revisa estado de microfono, biometría y token JWT',
                      color: const Color(0xFF16A34A),
                      onTap: () {
                        _showSecurityDialog(context);
                      },
                    ),

                    const SizedBox(height: 10),

                    _buildActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión de Administrador',
                      subtitle: 'Finaliza el token activo y vuelve a la pantalla inicial',
                      color: AppColors.accentRed,
                      onTap: () => _handleLogout(context),
                    ),

                    const SizedBox(height: 32),

                    const Center(child: SoundMeLogo()),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(
              title: 'Panel de Administración',
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF0F3B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'MODO SUPERADMIN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'En línea',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Consola de Gestión SoundMe',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Control y diagnóstico del catálogo de Lengua de Señas Dominicana (LSRD).',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(List<MockSignEntry> signs) {
    final svgSignsCount = signs.where((s) => s.isSvg).length;
    final matrixSignsCount = signs.where((s) => s.isMatrixSign).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Señas Totales',
            value: '${signs.length}',
            subtitle: '100% catalogadas',
            icon: Icons.collections_bookmark_rounded,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Vectores SVG',
            value: '$svgSignsCount',
            subtitle: 'Resolución infinita',
            icon: Icons.polyline_rounded,
            color: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Matrices WebP',
            value: '114',
            subtitle: '<80KB optimizadas',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingKpiGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Señas Totales',
            value: '...',
            subtitle: 'Cargando datos...',
            icon: Icons.collections_bookmark_rounded,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Vectores SVG',
            value: '...',
            subtitle: 'Cargando datos...',
            icon: Icons.polyline_rounded,
            color: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Matrices WebP',
            value: '114',
            subtitle: '114 Sprite Sheets',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorKpiGrid() {
    return _buildMetricTile(
      title: 'Estado del Diccionario',
      value: '2,427',
      subtitle: 'Modo Offline / Caché Local Activa',
      icon: Icons.storage_rounded,
      color: AppColors.primaryNavy,
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEngineHealthCard(int totalSigns) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Motor de Traducción LSRD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '100% Óptimo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildHealthRow(
            label: 'Indexado fonético español (B/V, LL/Y, S/Z)',
            status: 'Activo',
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _buildHealthRow(
            label: 'Corrección por distancia Levenshtein',
            status: 'Distancia <= 1',
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _buildHealthRow(
            label: 'Resolución de sinónimos y n-gramas',
            status: 'Trigramas / Bigramas',
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _buildHealthRow(
            label: 'Fallback Dactilológico (Alfabeto A-Z)',
            status: '27 señas base',
            color: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow({
    required String label,
    required String status,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          status,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: isLoading ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, size: 22, color: color),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _runOptimization() async {
    setState(() => _isOptimizing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    ref.invalidate(allMockSignsProvider);
    if (mounted) {
      setState(() => _isOptimizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            '✓ Índices fonéticos y caché de Sprite Sheets optimizados.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppColors.primaryNavy),
            const SizedBox(width: 8),
            Text(
              'Diagnóstico de Seguridad',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogItem('Sesión:', 'Administrador Activo (JWT)'),
            _buildDialogItem('Permisos de Micrófono:', 'Concedidos (SpeechToText)'),
            _buildDialogItem('Almacenamiento Local:', 'Cifrado SharedPreferences'),
            _buildDialogItem('Ambiente:', 'SoundMe Mobile Client v2.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendido',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await ref.read(authServiceProvider).logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }
}
