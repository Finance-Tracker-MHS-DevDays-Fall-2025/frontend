// lib/screens/investments_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/widgets/top_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';

class Asset {
  final String id;
  final String name;
  final double value;
  final double invested;
  final List<String> tags;
  Asset({
    required this.id,
    required this.name,
    required this.value,
    required this.invested,
    this.tags = const [],
  });
  double get profit => value - invested;
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Без названия',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      invested: (json['invested'] as num?)?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class InvestmentsScreen extends StatefulWidget {
  final RealApiService api;
  const InvestmentsScreen({super.key, required this.api});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // 🔹 Данные
  List<Asset> _assets = [
    Asset(id: '1', name: 'Акции RU', value: 195810.0, invested: 134102.26, tags: ['ru', 'stocks']),
    Asset(id: '2', name: 'Акции US', value: 912204.0, invested: 544231.30, tags: ['us', 'stocks']),
    Asset(id: '3', name: 'Облигации', value: 9751.0, invested: 7216.73, tags: ['bonds']),
    Asset(id: '4', name: 'Криптовалюта', value: 169779.0, invested: 196118.12, tags: ['crypto']),
    Asset(id: '5', name: 'Валюта', value: 41545.0, invested: 41545.0, tags: ['cash']),
  ];

  List<Dividend> _dividends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDividends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDividends() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.api.getDividends();
      if (mounted) {
        setState(() => _dividends = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Не удалось загрузить дивиденды')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔔 Уведомления — Coming Soon')),
    );
  }

  void _showAddAssetDialog() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '0');
    final investedCtrl = TextEditingController(text: '0');
    String selectedType = 'stocks_ru';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('➕ Добавить актив'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Стоимость (₽)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: investedCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Вложено (₽)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Тип актива'),
                items: [
                  const DropdownMenuItem(value: 'stocks_ru', child: Text('Акции RU')),
                  const DropdownMenuItem(value: 'stocks_us', child: Text('Акции US')),
                  const DropdownMenuItem(value: 'bonds', child: Text('Облигации')),
                  const DropdownMenuItem(value: 'crypto', child: Text('Криптовалюта')),
                  const DropdownMenuItem(value: 'cash', child: Text('Валюта')),
                ],
                onChanged: (v) => setState(() => selectedType = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Navigator.of(ctx).pop, child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Укажите название')));
                return;
              }
              final value = double.tryParse(valueCtrl.text) ?? 0.0;
              final invested = double.tryParse(investedCtrl.text) ?? 0.0;
              if (value < 0 || invested < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Суммы не могут быть отрицательными')));
                return;
              }
              setState(() {
                _assets.add(Asset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  value: value,
                  invested: invested,
                  tags: _getTagsFromType(selectedType),
                ));
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  List<String> _getTagsFromType(String type) {
    switch (type) {
      case 'stocks_ru': return ['ru', 'stocks'];
      case 'stocks_us': return ['us', 'stocks'];
      case 'bonds': return ['bonds'];
      case 'crypto': return ['crypto'];
      case 'cash': return ['cash'];
      default: return [];
    }
  }

  IconData _getIconForAssetTags(List<String> tags) {
    if (tags.contains('stocks') && tags.contains('ru')) return Icons.bar_chart_outlined;
    if (tags.contains('stocks') && tags.contains('us')) return Icons.trending_up_outlined;
    if (tags.contains('bonds')) return Icons.receipt_long_outlined;
    if (tags.contains('crypto')) return Icons.currency_bitcoin_outlined;
    if (tags.contains('cash')) return Icons.money_outlined;
    return Icons.category_outlined;
  }

  Color _getColorForAssetIndex(int index) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFF00C4B4),
      const Color(0xFFA020F0),
      const Color(0xFFFFD700),
      const Color(0xFFE5E5E5),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFF9ED69),
    ];
    return colors[index % colors.length];
  }

  double get _portfolioValue => _assets.fold(0.0, (sum, a) => sum + a.value);
  double get _totalInvested => _assets.fold(0.0, (sum, a) => sum + a.invested);
  double get _profit => _portfolioValue - _totalInvested;
  double get _roiPercent => _totalInvested > 0 ? (_profit / _totalInvested * 100) : 0.0;
  double get _passiveIncome => _dividends.fold(0.0, (sum, d) => sum + (d.amount ?? 0));
  double get _passiveIncomeYearly => _passiveIncome * 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: TopAppBar(
        api: widget.api,
        currentPage: TopPage.investments,
        onNotificationsPressed: _showNotifications,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00C4B4),
              tabs: const [
                Tab(text: 'Портфель'),
                Tab(text: 'Дивиденды'),
                Tab(text: 'Доход'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPortfolioTab(),
                  _buildDividendsTab(),
                  _buildIncomeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: const Color(0xFF00C4B4),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildPortfolioTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildTopStatsCards(),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Структура портфеля',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      _buildPieChart(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Активы',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      _buildAssetsList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}

  Widget _buildPieChart() {
  if (_assets.isEmpty) {
    return Center(
      child: Text('Нет активов', style: TextStyle(color: Colors.grey[500])),
    );
  }

  final List<PieChartSectionData> sections = _assets.asMap().entries.map((entry) {
    final int index = entry.key;
    final Asset asset = entry.value;

    final double share = _portfolioValue > 0 ? (asset.value / _portfolioValue * 100) : 0.0;
    final Color color = _getColorForAssetIndex(index);

    return PieChartSectionData(
      color: color,
      value: asset.value,
      title: '${share.toStringAsFixed(1)}%',
      radius: 100,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();

  return AspectRatio(
    aspectRatio: 1.0,
    child: PieChart(
      PieChartData(
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    ),
  );
}
  Widget _buildTopStatsCards() {
    return Row(
      children: [
        Expanded(child: _statCard('Стоимость', _portfolioValue, '₽', Icons.account_balance_wallet_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Прибыль', _profit, '₽', Icons.trending_up_outlined, _profit > 0 ? Colors.green : Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('ROI', _roiPercent, '%', Icons.show_chart_outlined, Colors.purple, fixed: 2)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Доход', _passiveIncome, '₽', Icons.monetization_on_outlined, Colors.teal)),
      ],
    );
  }

  Widget _statCard(String title, double value, String unit, IconData icon, Color color, {int fixed = 0}) {
    String formatValue() {
      if (unit == '%') {
        return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(fixed)}$unit';
      }
      final abs = value.abs();
      final prefix = value < 0 ? '−' : '';
      return '$prefix${abs.toInt()} $unit';
    }
    String subtitle() {
      if (unit == '%') return '${_totalInvested.toInt()} ₽ вложено';
      return '${_passiveIncomeYearly.toInt()} ₽/год';
    }
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Text(formatValue(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateColor.resolveWith((_) => Colors.grey[800]!),
        dataRowColor: MaterialStateColor.resolveWith((_) => Colors.grey[900]!),
        columns: [
          DataColumn(label: Text('ID', style: const TextStyle(color: Colors.white))), // 👈 Белый цвет
          DataColumn(label: Text('Актив', style: const TextStyle(color: Colors.white))),
          DataColumn(label: Text('₽', style: const TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Вложено', style: const TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Прибыль', style: const TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('ROI', style: const TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Доля', style: const TextStyle(color: Colors.white)), tooltip: ''),
        ],
        rows: _assets.map((asset) {
          final profit = asset.profit;
          final roi = asset.invested > 0 ? (profit / asset.invested * 100) : 0.0;
          final share = _portfolioValue > 0 ? (asset.value / _portfolioValue * 100) : 0.0;
          final color = profit > 0 ? Colors.green : profit < 0 ? Colors.red : Colors.grey[400];

          return DataRow(
            cells: [
              DataCell(Text(asset.id, style: const TextStyle(fontSize: 11, color: Colors.white))), // 👈 Белый цвет
              DataCell(Text(asset.name, style: const TextStyle(color: Colors.white))), // 👈 Белый цвет
              DataCell(Text('${asset.value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))), // 👈 Белый цвет
              DataCell(Text('${asset.invested.toInt()}', style: const TextStyle(color: Colors.white))), // 👈 Белый цвет
              DataCell(Text('${profit >= 0 ? '+' : '−'}${profit.abs().toInt()}', style: TextStyle(color: color))), // Цвет зависит от прибыли
              DataCell(Text('${roi >= 0 ? '+' : '−'}${roi.toStringAsFixed(1)}%', style: TextStyle(color: color))), // Цвет зависит от ROI
              DataCell(Text('${share.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white))), // 👈 Белый цвет
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDividendsTab() {
    if (_dividends.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Нет дивидендов', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _dividends.length,
      itemBuilder: (context, index) {
        final d = _dividends[index];
        return Card(
          color: Colors.grey[850],
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.payments_outlined, size: 20, color: Colors.green),
            ),
            title: Text(d.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${d.date.day}.${d.date.month}.${d.date.year} — ${(d.amount ?? 0).toStringAsFixed(2)} ₽',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _incomeCard('Всего', _passiveIncome),
          const SizedBox(height: 16),
          _incomeCard('Ожидаемо в год', _passiveIncomeYearly),
          const SizedBox(height: 16),
          _incomeCard('Прибыль портфеля', _profit),
        ],
      ),
    );
  }

  Widget _incomeCard(String title, double amount) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text('${amount.toInt()} ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}