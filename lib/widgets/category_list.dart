import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final double value;
  final bool isIncome;

  CategoryItem({required this.name, required this.value, required this.isIncome});
}

class CategoryList extends StatelessWidget {
  final List<CategoryItem> categories;

  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories.map((c) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(c.name, style: const TextStyle(fontSize: 15)),
        trailing: Text(
          '${c.value.toStringAsFixed(0)} ₽',
          style: TextStyle(
            color: c.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(
          c.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
          color: c.isIncome ? Colors.green : Colors.red,
        ),
      )).toList(),
    );
  }
}