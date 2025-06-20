// TODO Implement this library.
import 'package:epilist/models/list_item.dart';

class ShoppingListItem {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final List<ListItem> items;

  ShoppingListItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.items,
  });
}
