// Provider de ventas
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

// clase SalesNotifier
class SalesNotifier extends Notifier<List<Sale>> {
  @override
  List<Sale> build() => ref.read(storageServiceProvider).getSales();

  // funcion add
  void add(double amount) {
    final sale = Sale(id: _uuid.v4(), amount: amount, date: DateTime.now().toIso8601String());
    final updated = [...state, sale];
    state = updated;
    ref.read(storageServiceProvider).saveSales(updated);
  }
}

final salesProvider = NotifierProvider<SalesNotifier, List<Sale>>(SalesNotifier.new);