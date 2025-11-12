// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String?,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      categoryId: json['categoryId'] as String? ?? '',
      source: json['source'] as String,
      fromAccountId: json['fromAccountId'] as String? ?? 'default-cash',
      toAccountId: json['toAccountId'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'type': instance.type,
      'category': instance.category,
      'categoryId': instance.categoryId,
      'source': instance.source,
      'fromAccountId': instance.fromAccountId,
      'toAccountId': instance.toAccountId,
      'description': instance.description,
    };
