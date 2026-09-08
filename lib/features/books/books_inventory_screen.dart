import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
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

  factory BookInventoryItem.fromMap(Map<String, dynamic> map) {
    return BookInventoryItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'ملزمة دراسية',
      teacher: map['teacher']?['name']?.toString() ?? 'إدارة السنتر',
      grade: map['academicYear']?['name']?.toString() ?? '',
      price: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      sold: (map['_count']?['sales'] as num?)?.toInt() ?? 0,
    );
  }
}

class BooksInventoryScreen extends ConsumerStatefulWidget {
  const BooksInventoryScreen({super.key});

  @override
  ConsumerState<BooksInventoryScreen> createState() => _BooksInventoryScreenState();
}

class _BooksInventoryScreenState extends ConsumerState<BooksInventoryScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final booksAsync = ref.watch(liveBooksProvider);

    final rawList = booksAsync.value ?? [];
    final books = rawList.map((m) => BookInventoryItem.fromMap(m)).toList();

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
      body: RefreshIndicator(
        onRefresh: () async {
          SoundService.lightImpact();
          ref.invalidate(liveBooksProvider);
          ref.invalidate(liveLowStockBooksProvider);
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم الملزمة أو المدرس أو الكود...',
                  prefixIcon: Icon(LucideIcons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() => searchQuery = val);
                },
              ),
            ),

            // Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: branding.primaryColor.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي الملازم: ${books.length}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  Text(
                    '${books.where((b) => b.stock <= 10).length} ملزمة شارفت على النفاد ⚠️',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),

            // List of Books
            Expanded(
              child: booksAsync.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: branding.primaryColor),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('تعذر تحميل مخزن الملازم: $err', style: GoogleFonts.cairo(color: Colors.red)),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bookOpen, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد ملازم مضافة للمخزن بعد',
                            style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
            );
          },
        ),
      ),
          ],
        ),
      ),
    );
  }
}
