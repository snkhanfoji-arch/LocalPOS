import 'package:flutter/material';
import '../models/sale.dart';
import '../providers/pos_provider.dart';

class CartItemWidget extends StatelessWidget {
  final SaleItem item;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: Row(
          children: [
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pkrFormatter.format(item.price)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Total: ${pkrFormatter.format(item.total)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Control with larger target touchareas
            Row(
              children: [
                IconButton(
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: theme.colorScheme.primary,
                  iconSize: 28,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.quantity.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.primary,
                  iconSize: 28,
                ),
              ],
            ),

            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
