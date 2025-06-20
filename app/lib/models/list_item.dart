class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  bool isPurchased;

  ListItem({
    required this.id,
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.isPurchased = false,
  });
}
