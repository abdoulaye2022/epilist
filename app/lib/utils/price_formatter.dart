// utils/price_formatter.dart
class PriceFormatter {
  static String formatCAD(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  static String formatCADShort(double price) {
    return '${price.toStringAsFixed(2)}\$';
  }
}
