import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/inventory_item.dart';
import '../models/order.dart';
import '../models/debt.dart';

const String _baseUrl = 'http://127.0.0.1:8000';

class ApiService {
  // Customers
  static Future<List<Client>> getClients() async {
    final response = await http.get(Uri.parse('$_baseUrl/customers/all'));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Client.fromJson(e)).toList();
    }
    throw Exception('Error al obtener clientes');
  }

  static Future<Map<String, dynamic>> getClientsPaged({
    int page = 1,
    int size = 40,
    String search = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/customers/').replace(
      queryParameters: {'page': '$page', 'size': '$size', 'search': search},
    );
    final response = await http.get(uri);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'items': (data['items'] as List).map((e) => Client.fromJson(e)).toList(),
        'total': data['total'] as int,
        'pages': data['pages'] as int,
      };
    }
    throw Exception('Error al obtener clientes paginados');
  }

  static Future<Client> createClient(Client client) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(client.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Client.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear cliente: ${response.body}');
  }

  static Future<Client> updateClient(Client client) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/${client.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(client.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Client.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar cliente: ${response.body}');
  }

  static Future<void> deleteClient(String document) async {
    final response = await http.delete(Uri.parse('$_baseUrl/customers/$document'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar cliente');
    }
  }

  static Future<List<Map<String, String>>> getProductTypes() async {
    final response = await http.get(Uri.parse('$_baseUrl/products/types'));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((e) => {'id': e['id'].toString(), 'name': e['name'] as String}).toList();
    }
    return [];
  }

  static Future<List<InventoryItem>> getProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products/all'));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((e) => InventoryItem.fromJson(e)).toList();
    }
    throw Exception('Error al obtener productos');
  }

  static Future<Map<String, dynamic>> getProductsPaged({
    int page = 1,
    int size = 40,
    String search = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/products/').replace(
      queryParameters: {'page': '$page', 'size': '$size', 'search': search},
    );
    final response = await http.get(uri);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'items': (data['items'] as List).map((e) => InventoryItem.fromJson(e)).toList(),
        'total': data['total'] as int,
        'pages': data['pages'] as int,
      };
    }
    throw Exception('Error al obtener productos paginados');
  }

  static Future<InventoryItem> createProduct(InventoryItem item) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear producto: ${response.body}');
  }

  static Future<InventoryItem> updateProduct(InventoryItem item) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar producto: ${response.body}');
  }

  static Future<void> adjustProductStock(String id, num delta) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/products/$id/stock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'delta': delta}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar stock: ${response.body}');
    }
  }

  static Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/products/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }

  // Orders
  static Future<Map<String, dynamic>> getOrdersPaged({
    int page = 1,
    int size = 20,
    String search = '',
    String status = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'search': search,
        'status': status,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'items': (data['items'] as List).map((e) => Order.fromJson(e)).toList(),
        'total': data['total'] as int,
        'pages': data['pages'] as int,
      };
    }
    throw Exception('Error al obtener pedidos paginados');
  }

  static Future<Order> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orders/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear orden: ${response.body}');
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/orders/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado: ${response.body}');
    }
  }

  static Future<void> createOrderDetail({
    required String orderId,
    required String customerDocument,
    required String productId,
    required double amount,
    required double salePrice,
  }) async {
    final subtotal = amount * salePrice;
    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/details'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'order_id': int.parse(orderId),
        'customer_document': customerDocument,
        'product_id': int.parse(productId),
        'amount': amount,
        'sale_price': salePrice,
        'subtotal': subtotal,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al crear detalle: ${response.body}');
    }
  }

  // Debts (credit table)
  static Future<List<Debt>> getDebts() async {
    final response = await http.get(Uri.parse('$_baseUrl/credits/all'));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Debt.fromJson(e)).toList();
    }
    throw Exception('Error al obtener deudas');
  }

  static Future<Map<String, dynamic>> getDebtsPaged({
    int page = 1,
    int size = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/credits/').replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'items': (data['items'] as List).map((e) => Debt.fromJson(e)).toList(),
        'total': data['total'] as int,
        'pages': data['pages'] as int,
      };
    }
    throw Exception('Error al obtener deudas paginadas');
  }

  static Future<Debt> createDebt(Debt debt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/credits/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(debt.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Debt.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear deuda: ${response.body}');
  }

  static Future<void> toggleDebtPaid(int id, bool paid) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/credits/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': paid ? 'P' : 'A'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar deuda');
    }
  }
}
