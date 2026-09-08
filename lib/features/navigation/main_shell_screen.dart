import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/branding_service.dart';
import '../../core/services/security_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import '../academic/academic_groups_screen.dart';
import '../academic/groups_management_screen.dart';
import '../academic/subjects_management_screen.dart';
import '../academic/academic_years_management_screen.dart';
import '../admissions/admissions_screen.dart';
import '../attendance/attendance_scanner_screen.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../books/books_inventory_screen.dart';
import '../cashier/financial_ledger_screen.dart';
import '../cashier/mobile_pos_screen.dart';
import '../quota/quota_topup_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../dashboard/assistant_dashboard_screen.dart';
import '../dashboard/teacher_dashboard_screen.dart';
import '../platform/online_platform_screen.dart';
import '../platform/platform_settings_screen.dart';
import '../settings/branding_settings_screen.dart';
import '../staff/staff_management_screen.dart';
import '../students/students_list_screen.dart';
import '../teacher/live_class_cockpit_screen.dart';
import '../teacher/teacher_earnings_screen.dart';
import '../teacher/teacher_settlements_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final branding = ref.watch(brandingProvider);

    // 1. Loading State (Full Screen Loader)
    if (auth.isLoading && auth.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: branding.primaryColor),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل بيانات النظام والتحقق من الجلسة...',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Unauthenticated State (Direct to AuthScreen)
    if (!auth.isAuthenticated || auth.user == null) {
      return const AuthScreen();
    }

    final user = auth.user;

    // Build role-specific tabs
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (user?.isTeacher ?? false) {
      screens = const [
        TeacherDashboardScreen(),
        LiveClassCockpitScreen(
          groupName: 'مجموعة 3ث لغة عربية (أ)',
          sessionNumber: 5,
        ),
        TeacherEarningsScreen(),
        BrandingSettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.home),
          label: 'حصصي',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.checkSquare),
          label: 'رصد القاعة',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.wallet),
          label: 'أرباحي',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.settings),
          label: 'الإعدادات',
        ),
      ];
    } else if (user?.isAssistant ?? false) {
      screens = const [
        AssistantDashboardScreen(),
        AttendanceScannerScreen(),
        MobilePosScreen(),
        StudentsListScreen(),
        BrandingSettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.layoutDashboard),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.scanLine),
          label: 'الماسح',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.receipt),
          label: 'الخزينة POS',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.users),
          label: 'الطلاب',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.settings),
          label: 'الإعدادات',
        ),
      ];
    } else {
      // Default: Owner / Admin
      screens = const [
        AdminDashboardScreen(),
        FinancialLedgerScreen(),
        TeacherSettlementsScreen(),
        StudentsListScreen(),
        BrandingSettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.barChart3),
          label: 'الرادار',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.fileSpreadsheet),
          label: 'الماليات',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.graduationCap),
          label: 'المدرسين',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.users),
          label: 'الطلاب',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.palette),
          label: 'الهوية',
        ),
      ];
    }

    // Guard against index out of bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      drawer: _buildAppDrawer(context, ref, branding, user),
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                  ? Image.network(
                      branding.logoUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/zorar_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(LucideIcons.sparkles, color: branding.primaryColor, size: 20),
                      ),
                    )
                  : Image.asset(
                      'assets/images/zorar_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(LucideIcons.sparkles, color: branding.primaryColor, size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branding.centerName,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.roleArabicTitle ?? 'نظام زُرار الميداني',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: branding.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              branding.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              size: 20,
            ),
            tooltip: 'تبديل المظهر',
            onPressed: () {
              SoundService.lightImpact();
              ref.read(brandingProvider.notifier).toggleDarkMode();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.lock, size: 19),
            tooltip: 'قفل الخزينة',
            onPressed: () {
              SecurityService.showSecurityPinDialog(context, title: 'قفل الخزينة');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) {
          SoundService.successFeedback();
          setState(() => _currentIndex = idx);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: branding.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11.5),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10.5),
        items: navItems,
      ),
    );
  }

  Widget _buildAppDrawer(
    BuildContext context,
    WidgetRef ref,
    BrandingModel branding,
    UserModel? user,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [branding.primaryColor, const Color(0xFF0F172A)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                          ? Image.network(
                              branding.logoUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/zorar_icon.png',
                                width: 44,
                                height: 44,
                                errorBuilder: (_, __, ___) => const Icon(LucideIcons.sparkles, color: Colors.white),
                              ),
                            )
                          : Image.asset(
                              'assets/images/zorar_icon.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(LucideIcons.sparkles, color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        branding.centerName,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${user?.name} (${user?.roleArabicTitle})',
                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الكوتا: ${parseInt(user?.tenant?['quotaBalance'], 100)}',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section 1: Daily Operations
          _buildDrawerSectionTitle('العمليات الميدانية'),
          ListTile(
            leading: const Icon(LucideIcons.qrCode),
            title: Text('ماسح الحضور والباركود', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AttendanceScannerScreen()));
            },
          ),
          if (user?.isTeacher ?? false) ...[
            ListTile(
              leading: const Icon(LucideIcons.penTool),
              title: Text('رصد درجات وواجب الحصة', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const LiveClassCockpitScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.wallet),
              title: Text('كشف أرباحي وعمولاتي', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TeacherEarningsScreen()));
              },
            ),
          ],
          if (!(user?.isTeacher ?? false)) ...[
            ListTile(
              leading: const Icon(LucideIcons.receipt),
              title: Text('نقطة البيع والتحصيل (POS)', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MobilePosScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.clipboardList),
              title: Text('طلبات التقديم والحجز', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AdmissionsScreen()));
              },
            ),
          ],

          const Divider(),

          // Section 2: Academic & Students
          _buildDrawerSectionTitle('الشؤون الأكاديمية والصفوف'),
          ListTile(
            leading: const Icon(LucideIcons.users),
            title: Text('دليل وقيد الطلاب', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const StudentsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.layers),
            title: Text('إدارة المجموعات والقاعات', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const GroupsManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.bookOpen),
            title: Text('المواد الدراسية', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SubjectsManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.graduationCap),
            title: Text('الصفوف وتخصيص البكالوريا', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AcademicYearsManagementScreen()));
            },
          ),
          if (!(user?.isTeacher ?? false))
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: Text('مخزن الملازم والمذكرات', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BooksInventoryScreen()));
              },
            ),

          if (user?.isAdmin ?? true) ...[
            const Divider(),

            // Section 3: Admin & Finance
            _buildDrawerSectionTitle('الإدارة والمنصة (Admin)'),
            ListTile(
              leading: const Icon(LucideIcons.gauge, color: Color(0xFF10B981)),
              title: Text('الرصيد وشحن باقات الطلاب', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'شحن رصيد',
                  style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const QuotaTopupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.video),
              title: Text('إدارة المنصة والكورسات والحصص', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const OnlinePlatformScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileSpreadsheet),
              title: Text('سجل وجرد المدفوعات والخزينة', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FinancialLedgerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.badgePercent),
              title: Text('تسويات وعمولات المعلمين', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TeacherSettlementsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shieldCheck),
              title: Text('فريق العمل والمساعدين', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const StaffManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.globe),
              title: Text('إعدادات المنصة والمتجر', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PlatformSettingsScreen()));
              },
            ),
          ],

          const Divider(),

          // Section 4: Settings & Branding
          _buildDrawerSectionTitle('الهوية والإعدادات'),
          ListTile(
            leading: const Icon(LucideIcons.shieldCheck),
            title: Text('حماية الخزينة برمز PIN', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              SecurityService.showSecurityPinDialog(context, title: 'إعدادات الحماية والأمان');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: Text('عن تطبيق زرار كود', style: GoogleFonts.cairo(fontSize: 13)),
            subtitle: Text('إصدار الإنتاج v1.0.1 (سحابي)', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'زرار كود • Zorar Code',
                applicationVersion: 'v1.0.1+1 (Production Release)',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/zorar_icon.png', width: 48, height: 48),
                ),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'المنظومة الميدانية السحابية المتكاملة لإدارة السناتر التعليمية، المساعدين، كروت الطلاب، ونقاط البيع المحمولة.',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
