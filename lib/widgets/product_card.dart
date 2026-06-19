import 'package:flutter/material';
import '../models/product.dart';
import '../providers/pos_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({
    required this.product,
    required this.onAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stock <= product.lowStockThreshold;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isLowStock
            ? BorderSide(color: theme.colorScheme.error, width: 1.5)
            : BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.category == 'Chicken'
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category == 'Chicken' ? 'Chicken / چکن' : 'Electric / بجلی',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: product.category == 'Chicken'
                      ? Colors.red.shade800
                      : Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Product Name
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // Price formatted in PKR
            Text(
              pkrFormatter.format(product.price),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 4),

            // Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock: ${product.stock.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLowStock ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LOW / کم',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: product.stock > 0 ? onAdd : null,
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text(
                  'Add / ڈالیں',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
