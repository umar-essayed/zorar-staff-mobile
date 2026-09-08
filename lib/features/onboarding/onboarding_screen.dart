import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_screen.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String badge;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.badge,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'ماسح حضور ذكي وفائق السرعة',
      description:
          'تسجيل حضور وانصراف الطلاب في أقل من 10ms عبر كاميرا الموبايل والباركود، مع اهتزازات لمسية ونغمات تنبيهية ودعم الحصص الاستثنائية بلمسة واحدة.',
      icon: LucideIcons.qrCode,
      accentColor: const Color(0xFF10B981),
      badge: 'سرعة استجابة Sub-10ms',
    ),
    OnboardingSlide(
      title: 'نقطة بيع وكاشير متنقلة (POS)',
      description:
          'تحصيل الاشتراكات والملازم، وطباعة إيصالات بلوتوث حرارية فورية على طابعات الجيب (58mm/80mm)، مع زر إرسال الإيصال الرسمي لواتساب ولي الأمر.',
      icon: LucideIcons.receipt,
      accentColor: const Color(0xFF3B82F6),
      badge: 'دعم طابعات البلوتوث المحمولة',
    ),
    OnboardingSlide(
      title: 'بوابة المعلم وغرفة الحصة الحية',
      description:
          'كشف حضور حي لطلاب القاعة، مع إمكانية رصد درجات التسميع الدوري والواجبات والملاحظات السلوكية بضغطة زر، ومتابعة كشف أرباح المعلم الخاصة.',
      icon: LucideIcons.graduationCap,
      accentColor: const Color(0xFF8B5CF6),
      badge: 'رصد فوري لدرجات الطلاب',
    ),
    OnboardingSlide(
      title: 'هوية مخصصة بالكامل لسنترك',
      description:
          'خصص ألوان وشعار واسم مؤسستك التعليمية، وقم بتبديل أيقونة التطبيق على شاشة الهاتف لتعكس علامتك التجارية بكل فخر واحترافية.',
      icon: LucideIcons.palette,
      accentColor: const Color(0xFFF59E0B),
      badge: 'White-Label & Dynamic App Icon',
    ),
  ];

  Future<void> _completeOnboarding() async {
    SoundService.successFeedback();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zorar_has_seen_onboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/zorar_icon.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(LucideIcons.sparkles, color: branding.primaryColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'زُرار كود (Zorar Code)',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'تخطي',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (ctx, index) {
                  final slide = slides[index];

                  return Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large Illustrative Icon Card
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                slide.accentColor,
                                slide.accentColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withOpacity(0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Feature Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: slide.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide.badge,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: slide.accentColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Slide Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Slide Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            color: Colors.grey[600],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Dots
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Smooth Animated Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (dotIdx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == dotIdx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == dotIdx
                              ? branding.primaryColor
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: branding.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (isLastPage) {
                          _completeOnboarding();
                        } else {
                          SoundService.successFeedback();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        isLastPage ? 'ابدأ الآن في إدارة السنتر' : 'التالي',
                        style: GoogleFonts.cairo(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
