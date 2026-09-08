import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../cashier/mobile_pos_screen.dart';
import 'book_form_dialog.dart';

class BookInventoryItem {
  final String id;
  final String title;
  final String teacher;
  final String grade;
  final double price;
  int stock;
  final int sold;

  BookInventoryItem({
    required this.id,
    required this.title,
    required this.teacher,
    required this.grade,
    required this.price,
    required this.stock,
    required this.sold,
  });
}

class BooksInventoryScreen extends ConsumerStatefulWidget {
  const BooksInventoryScreen({super.key});

  @override
  ConsumerState<BooksInventoryScreen> createState() => _BooksInventoryScreenState();
}

class _BooksInventoryScreenState extends ConsumerState<BooksInventoryScreen> {
  String searchQuery = '';

  late final List<BookInventoryItem> books = [
    BookInventoryItem(
      id: 'BOK-01',
      title: 'ملزمة النحو والتدريبات الشاملة 2026',
      teacher: 'أ/ أحمد كمال (عربي)',
      grade: 'الصف الثالث الثانوي',
      price: 85,
      stock: 45,
      sold: 140,
    ),
    BookInventoryItem(
      id: 'BOK-02',
      title: 'مذكرة بنك أسئلة الكيمياء العضوية',
      teacher: 'أ/ حسام فؤاد (كيمياء)',
      grade: 'الصف الثاني الثانوي',
      price: 90,
      stock: 8, // Low stock!
      sold: 92,
    ),
    BookInventoryItem(
      id: 'BOK-03',
      title: 'كتاب شرح الفيزياء وقوانين نيوتن',
      teacher: 'أ/ محمد إبراهيم (فيزياء)',
      grade: 'الصف الأول الثانوي',
      price: 110,
      stock: 32,
      sold: 68,
    ),
    BookInventoryItem(
      id: 'BOK-04',
      title: 'ملزمة مراجعة البلاغة والنصوص',
      teacher: 'أ/ أحمد كمال (عربي)',
      grade: 'الصف الثالث الثانوي',
      price: 75,
      stock: 60,
      sold: 115,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    final filtered = books.where((b) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return b.title.toLowerCase().contains(q) ||
            b.teacher.toLowerCase().contains(q) ||
            b.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مخزن الملازم والمذكرات الدراسية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'إضافة ملزمة جديدة',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const BookFormDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Fast Stats Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم الملزمة، كودها، أو اسم المدرس...',
                    prefixIcon: Icon(LucideIcons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي الملازم المسجلة: ${books.length}',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'إجمالي المبيعات: ${books.fold<int>(0, (sum, b) => sum + b.sold)} نسخة',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = filtered[idx];
                final isLowStock = item.stock <= 10;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: branding.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.price.toInt()} ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: branding.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.teacher} • ${item.grade}',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? Colors.red.withOpacity(0.12)
                                        : const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLowStock ? 'متبقي ${item.stock} فقط ⚠️' : 'متوفر: ${item.stock} نسخة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isLowStock ? Colors.red : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تم بيع: ${item.sold}',
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(LucideIcons.shoppingCart, size: 16),
                              label: const Text('صرف / بيع'),
                              onPressed: () {
                                SoundService.successFeedback();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => const MobilePosScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
