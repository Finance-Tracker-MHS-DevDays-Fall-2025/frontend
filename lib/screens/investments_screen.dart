import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/widgets/top_app_bar.dart';
import 'dart:math' as math;

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
      id: json['id'] as String? ?? '',
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

  final List<Asset> _assets = [
    Asset(id: '1', name: 'Акции RU', value: 195810.0, invested: 134102.26, tags: ['ru', 'stocks']),
    Asset(id: '2', name: 'Акции US', value: 912204.0, invested: 544231.30, tags: ['us', 'stocks']),
    Asset(id: '3', name: 'Облигации', value: 9751.0, invested: 7216.73, tags: ['bonds']),
    Asset(id: '4', name: 'Криптовалюта', value: 169779.0, invested: 196118.12, tags: ['crypto']),
    Asset(id: '5', name: 'Валюта', value: 41545.0, invested: 41545.0, tags: ['cash']),
  ];

  List<Dividend> _dividends = [];
  bool _isLoading = false;
  int? _hoveredPieIndex;

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

  String _generateNextId() {
    if (_assets.isEmpty) return '1';
    final lastId = int.tryParse(_assets.last.id) ?? 0;
    return (lastId + 1).toString();
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
          const SnackBar(content: Text('Не удалось загрузить дивиденды')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotifications() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Уведомления — Coming Soon')),
    );
  }

  void _showAddAssetDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final quantityCtrl = TextEditingController(text: '1');
    String selectedType = 'stocks_ru';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить актив'),
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
                controller: priceCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Цена за единицу (₽)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Количество'),
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
                onChanged: (v) {
                  if (v != null) setState(() => selectedType = v);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(ctx).pop,
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Укажите название')),
                );
                return;
              }
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final quantity = double.tryParse(quantityCtrl.text) ?? 1.0;

              if (price < 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Цена не может быть отрицательной')),
                );
                return;
              }
              if (quantity <= 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Количество должно быть > 0')),
                );
                return;
              }

              final value = price * quantity;
              final invested = value;

              setState(() {
                _assets.add(Asset(
                  id: _generateNextId(),
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
      case 'stocks_ru':
        return ['ru', 'stocks'];
      case 'stocks_us':
        return ['us', 'stocks'];
      case 'bonds':
        return ['bonds'];
      case 'crypto':
        return ['crypto'];
      case 'cash':
        return ['cash'];
      default:
        return [];
    }
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

  // 🔹 Вычисляемые свойства
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
                        const Text(
                          'Структура портфеля',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
                        const Text(
                          'Активы',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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

  // Топ карточки с основными статистиками
  Widget _buildTopStatsCards() {
    Widget statCard(String title, String value, {Color? valueColor}) {
      return Expanded(
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    final profitColor = _profit > 0 ? Colors.green : _profit < 0 ? Colors.red : Colors.white;

    return Row(
      children: [
        statCard('Портфель', '${_portfolioValue.toInt()} ₽'),
        const SizedBox(width: 12),
        statCard('Вложено', '${_totalInvested.toInt()} ₽'),
        const SizedBox(width: 12),
        statCard('Прибыль', '${_profit >= 0 ? '+' : '−'}${_profit.abs().toInt()} ₽', valueColor: profitColor),
        const SizedBox(width: 12),
        statCard('ROI', '${_roiPercent.toStringAsFixed(1)}%'),
      ],
    );
  }

  // ✅ ГИПЕР-КРУТОЙ ГРАФИК ДЛЯ fl_chart — РАБОТАЕТ СРАЗУ
  Widget _buildPieChart() {
  if (_assets.isEmpty) {
    return Center(
      child: Text('Нет активов', style: TextStyle(color: Colors.grey[500])),
    );
  }

  final sections = _assets.asMap().entries.map((entry) {
    final i = entry.key;
    final asset = entry.value;
    final isHovered = _hoveredPieIndex == i;
    final color = _getColorForAssetIndex(i);

    return PieChartSectionData(
      value: asset.value,
      color: color.withOpacity(isHovered ? 1.0 : 0.85),
      radius: isHovered ? 58.0 : 52.0,
      showTitle: false,
      borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
    );
  }).toList();

  // Метки над секциями — оставим только при ховере, но ограничим позиционирование
  final labels = _assets.asMap().entries.map((entry) {
    final i = entry.key;
    final asset = entry.value;
    final isHovered = _hoveredPieIndex == i;
    final share = _portfolioValue > 0 ? asset.value / _portfolioValue : 0.0;

    if (!isHovered) return const SizedBox.shrink();

    // ⚠️ Улучшим позиционирование: ограничим вылет меток за границы
    final angle = 2 * math.pi * i / _assets.length - math.pi / 2;
    final radius = 84.0; // чуть меньше, чтобы не вылезала
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Positioned.directional(
      textDirection: TextDirection.ltr,
      top: 110 + y - 10, // смещение от центра (110 = половина 220)
      start: 110 + x - 30, // -30 ≈ ширина метки / 2
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${(share * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }).toList();

  return Center( // ← КЛЮЧЕВОЕ: явно центрируем
    child: SizedBox(
      width: 230, // чуть больше — даём пространство для меток
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 1.5,
              centerSpaceRadius: 64,
              startDegreeOffset: 270,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                  if (!mounted) return;
                  final touchedIndex = response?.touchedSection?.touchedSectionIndex;
                  if (event is FlTapUpEvent) {
                    setState(() => _hoveredPieIndex = _hoveredPieIndex == touchedIndex ? null : touchedIndex);
                  } else if (event is FlPointerHoverEvent) {
                    setState(() => _hoveredPieIndex = touchedIndex);
                  }
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.elasticOut,
          ),
          ...labels,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_portfolioValue.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₽',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
        headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[800]),
        dataRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[900]),
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Актив', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('₽', style: TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Вложено', style: TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Прибыль', style: TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('ROI', style: TextStyle(color: Colors.white)), tooltip: ''),
          DataColumn(label: Text('Доля', style: TextStyle(color: Colors.white)), tooltip: ''),
        ],
        rows: _assets.map((asset) {
          final profit = asset.profit;
          final roi = asset.invested > 0 ? (profit / asset.invested * 100) : 0.0;
          final share = _portfolioValue > 0 ? (asset.value / _portfolioValue * 100) : 0.0;
          final color = profit > 0 ? Colors.green : profit < 0 ? Colors.red : Colors.grey[400]!;

          return DataRow(
            cells: [
              DataCell(Text(asset.id, style: const TextStyle(fontSize: 11, color: Colors.white))),
              DataCell(Text(asset.name, style: const TextStyle(color: Colors.white))),
              DataCell(Text('${asset.value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataCell(Text('${asset.invested.toInt()}', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${profit >= 0 ? '+' : '−'}${profit.abs().toInt()}', style: TextStyle(color: color))),
              DataCell(Text('${roi >= 0 ? '+' : '−'}${roi.toStringAsFixed(1)}%', style: TextStyle(color: color))),
              DataCell(Text('${share.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white))),
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