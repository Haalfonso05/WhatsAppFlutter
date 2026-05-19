import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/inventory_item.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/debt.dart';
import '../models/sale.dart';

const _kUsers = 'mgmt_users';
const _kCurrentUser = 'mgmt_current_user';
const _kInventory = 'mgmt_inventory';
const _kOrders = 'mgmt_orders';
const _kClients = 'mgmt_clients';
const _kDebts = 'mgmt_debts';
const _kSales = 'mgmt_sales';

class StorageService {
  const StorageService(this._prefs);
  final SharedPreferences _prefs;

  List<T> _get<T>(String key, T Function(Map<String, dynamic>) from) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => from(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _set<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) =>
      _prefs.setString(key, jsonEncode(items.map(toJson).toList()));

  // Auth
  List<AppUser> getUsers() => _get(_kUsers, AppUser.fromJson);
  Future<void> saveUsers(List<AppUser> v) => _set(_kUsers, v, (u) => u.toJson());

  UserSession? getCurrentUser() {
    final raw = _prefs.getString(_kCurrentUser);
    if (raw == null) return null;
    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(UserSession u) =>
      _prefs.setString(_kCurrentUser, jsonEncode(u.toJson()));
  Future<void> clearCurrentUser() async => _prefs.remove(_kCurrentUser);

  // Inventory
  List<InventoryItem> getInventory() => _get(_kInventory, InventoryItem.fromJson);
  Future<void> saveInventory(List<InventoryItem> v) => _set(_kInventory, v, (i) => i.toJson());

  // Orders
  List<Order> getOrders() => _get(_kOrders, Order.fromJson);
  Future<void> saveOrders(List<Order> v) => _set(_kOrders, v, (o) => o.toJson());

  // Clients
  List<Client> getClients() => _get(_kClients, Client.fromJson);
  Future<void> saveClients(List<Client> v) => _set(_kClients, v, (c) => c.toJson());

  // Debts
  List<Debt> getDebts() => _get(_kDebts, Debt.fromJson);
  Future<void> saveDebts(List<Debt> v) => _set(_kDebts, v, (d) => d.toJson());

  // Sales
  List<Sale> getSales() => _get(_kSales, Sale.fromJson);
  Future<void> saveSales(List<Sale> v) => _set(_kSales, v, (s) => s.toJson());
}

// Overridden in main.dart with a real SharedPreferences instance
final storageServiceProvider = Provider<StorageService>((_) => throw UnimplementedError());
