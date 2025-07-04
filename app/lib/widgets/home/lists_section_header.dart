// widgets/home/lists_section_header.dart
import 'package:flutter/material.dart';

class ListsSectionHeader extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onCreateNew;

  const ListsSectionHeader({
    super.key,
    required this.onViewAll,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        if (isSmallScreen) {
          // Layout vertical pour petits écrans
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes Listes d\'Épicerie',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'Voir tout',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onCreateNew,
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Nouvelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Layout horizontal pour grands écrans
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mes Listes d\'Épicerie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'Voir tout',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onCreateNew,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Nouvelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}
