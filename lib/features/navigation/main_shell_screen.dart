import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/branding_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../academic/academic_groups_screen.dart';
import '../admissions/admissions_screen.dart';
import '../attendance/attendance_scanner_screen.dart';
import '../auth/auth_provider.dart';
import '../books/books_inventory_screen.dart';
import '../cashier/financial_ledger_screen.dart';
import '../cashier/mobile_pos_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../dashboard/assistant_dashboard_screen.dart';
import '../dashboard/teacher_dashboard_screen.dart';
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
              child: Image.asset(
                'assets/images/zorar_icon.png',
                width: 28,
                height: 28,
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
          // Quick Role Switcher Action in AppBar
          PopupMenuButton<String>(
            tooltip: 'تبديل دور المستخدم للتجربة',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: branding.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.users, size: 14, color: branding.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'تبديل الدور',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: branding.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (role) {
              SoundService.successFeedback();
              ref.read(authProvider.notifier).switchDemoRole(role);
              setState(() => _currentIndex = 0);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: AppConstants.roleOwner,
                child: Text('👑 الإدارة وصاحب السنتر', style: GoogleFonts.cairo()),
              ),
              PopupMenuItem(
                value: AppConstants.roleAssistant,
                child: Text('💼 المساعد والكاشير', style: GoogleFonts.cairo()),
              ),
              PopupMenuItem(
                value: AppConstants.roleTeacher,
                child: Text('👨‍🏫 المعلم وقاعة الحصة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              branding.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              size: 20,
            ),
            tooltip: 'تبديل الوضع الليلي',
            onPressed: () {
              SoundService.successFeedback();
              ref.read(brandingProvider.notifier).toggleDarkMode();
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
                      child: Image.asset(
                        'assets/images/zorar_icon.png',
                        width: 36,
                        height: 36,
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
                Text(
                  '${user?.name} (${user?.roleArabicTitle})',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Section 1: Daily Operations
          _buildDrawerSectionTitle('العمليات اليومية والميدانية'),
          ListTile(
            leading: const Icon(LucideIcons.qrCode),
            title: Text('ماسح الحضور السريع', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AttendanceScannerScreen()));
            },
          ),
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
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
              child: Text('2 جديد', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AdmissionsScreen()));
            },
          ),

          const Divider(),

          // Section 2: Academic & Students
          _buildDrawerSectionTitle('الشؤون الأكاديمية والطلاب'),
          ListTile(
            leading: const Icon(LucideIcons.users),
            title: Text('دليل شؤون الطلاب', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const StudentsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.layers),
            title: Text('المجموعات والمراحل الدراسية', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AcademicGroupsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.bookOpen),
            title: Text('مخزن الملازم والمذكرات', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BooksInventoryScreen()));
            },
          ),

          if (user?.isAdmin ?? true) ...[
            const Divider(),

            // Section 3: Admin & Finance
            _buildDrawerSectionTitle('الإدارة والماليات (Admin)'),
            ListTile(
              leading: const Icon(LucideIcons.fileSpreadsheet),
              title: Text('سجل وجرد المدفوعات', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FinancialLedgerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.graduationCap),
              title: Text('تسويات وعمولات المعلمين', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TeacherSettlementsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shieldCheck),
              title: Text('فريق العمل والصلاحيات', style: GoogleFonts.cairo(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const StaffManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.globe),
              title: Text('المنصة والمتجر الإلكتروني', style: GoogleFonts.cairo(fontSize: 13)),
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
            leading: const Icon(LucideIcons.palette),
            title: Text('تخصيص الهوية والأيقونة', style: GoogleFonts.cairo(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BrandingSettingsScreen()));
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
