import 'package:flutter/material.dart';
import '../../core/network/edu_api_service.dart';

class PlatformAnalyticsScreen extends StatefulWidget {
  final String? teacherId;
  const PlatformAnalyticsScreen({super.key, this.teacherId});

  @override
  State<PlatformAnalyticsScreen> createState() => _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await EduApiService().getPlatformAnalytics(teacherId: widget.teacherId);
      if (mounted) {
        setState(() {
          _analyticsData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل تحليلات المنصة: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تحليلات المنصة والطلاب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: _loadAnalytics,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.insights, size: 20), text: 'نظرة عامة'),
              Tab(icon: Icon(Icons.video_library, size: 20), text: 'الكورسات'),
              Tab(icon: Icon(Icons.quiz, size: 20), text: 'الكويزات والنتائج'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadAnalytics,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(primary),
                      _buildCoursesTab(primary),
                      _buildQuizzesTab(primary),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverviewTab(Color primary) {
    final summary = _analyticsData?['summary'] as Map<String, dynamic>? ?? {};
    final totalCourses = summary['totalCourses'] ?? 0;
    final totalLessons = summary['totalLessons'] ?? 0;
    final totalQuizzes = summary['totalQuizzes'] ?? 0;
    final totalEnrollments = summary['totalEnrollments'] ?? 0;
    final uniqueStudents = summary['uniqueStudents'] ?? 0;
    final activeWatchers = summary['activeWatchers'] ?? 0;
    final totalWatchHours = summary['totalWatchHours'] ?? 0;
    final quizPassRate = (summary['quizPassRate'] ?? 0).toDouble();

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Highlight Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.75)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي الطلاب المسجلين بالمنصة',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$uniqueStudents طالب',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إجمالي اشتراكات الكورسات: $totalEnrollments اشتراك',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'المشاهدين النشطين',
                value: '$activeWatchers',
                subtitle: 'شاهدوا دروساً مؤخراً',
                icon: Icons.play_circle_fill,
                color: Colors.teal,
              ),
              _buildStatCard(
                title: 'ساعات المشاهدة',
                value: '$totalWatchHours س',
                subtitle: 'إجمالي المشاهدة الفعلية',
                icon: Icons.timer,
                color: Colors.indigo,
              ),
              _buildStatCard(
                title: 'محتوى المنصة',
                value: '$totalCourses كورس',
                subtitle: '$totalLessons حصة فيديو',
                icon: Icons.video_collection,
                color: Colors.purple,
              ),
              _buildStatCard(
                title: 'نسبة النجاح بالكويزات',
                value: '${quizPassRate.toStringAsFixed(1)}%',
                subtitle: 'من $totalQuizzes كويز متاح',
                icon: Icons.check_circle,
                color: Colors.orange.shade800,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'حالة إنجاز الطلاب للمحتوى',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نسبة النجاح الإجمالية:'),
                      Text(
                        '${quizPassRate.toStringAsFixed(1)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (quizPassRate / 100.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        quizPassRate >= 60 ? Colors.green : Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تعتمد نسبة النجاح على إجمالي إجابات الطلاب لكافة امتحانات الحصص والفصول.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab(Color primary) {
    final courses = (_analyticsData?['coursesAnalytics'] as List<dynamic>?) ?? [];

    if (courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_back_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد كورسات مسجلة أو تحليلات حتى الآن'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = courses[index] as Map<String, dynamic>;
          final title = c['title'] ?? 'بدون عنوان';
          final level = c['level'] ?? '';
          final totalEnrollments = c['totalEnrollments'] ?? 0;
          final activeStudents = c['activeStudents'] ?? 0;
          final completionRate = (c['completionRate'] ?? 0).toDouble();
          final lessonsCount = c['lessonsCount'] ?? 0;
          final quizSubmissionsCount = c['quizSubmissionsCount'] ?? 0;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.school_outlined, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (level.isNotEmpty)
                              Text(
                                level,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metricBadge('المشتركون', '$totalEnrollments', Icons.people, Colors.blue),
                      _metricBadge('النشطون', '$activeStudents', Icons.play_arrow, Colors.teal),
                      _metricBadge('الحصص', '$lessonsCount', Icons.video_collection, Colors.purple),
                      _metricBadge('إجابات الكويز', '$quizSubmissionsCount', Icons.assignment_turned_in, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نسبة الإتمام:', style: TextStyle(fontSize: 12)),
                      Text('${completionRate.toStringAsFixed(1)}%',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (completionRate / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionRate >= 50 ? Colors.green : primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metricBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuizzesTab(Color primary) {
    final quizzes = (_analyticsData?['quizzesAnalytics'] as List<dynamic>?) ?? [];

    if (quizzes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد اختبارات أو تسليمات كويز بعد'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final q = quizzes[index] as Map<String, dynamic>;
          final title = q['title'] ?? 'كويز بدون عنوان';
          final totalSubmissions = q['totalSubmissions'] ?? 0;
          final avgScore = (q['avgScore'] ?? 0).toDouble();
          final passRate = (q['passRate'] ?? 0).toDouble();
          final highestScore = q['highestScore'] ?? 0;
          final lowestScore = q['lowestScore'] ?? 0;
          final recent = (q['recentSubmissions'] as List<dynamic>?) ?? [];

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Text('التسليمات: $totalSubmissions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 12),
                    Text('متوسط الدرجات: ${avgScore.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                    const SizedBox(width: 12),
                    Text('نسبة النجاح: ${passRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: passRate >= 60 ? Colors.green : Colors.redAccent)),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _quizMiniStat('أعلى درجة', '$highestScore%', Colors.green),
                          _quizMiniStat('أقل درجة', '$lowestScore%', Colors.redAccent),
                          _quizMiniStat('نسبة النجاح', '${passRate.toStringAsFixed(0)}%', Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'آخر تسليمات الطلاب:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      if (recent.isEmpty)
                        const Text('لا توجد تسليمات مسجلة', style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        ...recent.take(5).map((sub) {
                          final studentName = sub['studentName'] ?? 'طالب';
                          final score = sub['score'] ?? 0;
                          final passed = sub['passed'] == true;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  passed ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: passed ? Colors.green : Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(studentName, style: const TextStyle(fontSize: 13)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (passed ? Colors.green : Colors.redAccent).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$score%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: passed ? Colors.green : Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quizMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
