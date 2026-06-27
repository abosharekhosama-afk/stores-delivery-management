enum TransactionType { order_revenue, withdrawal, refund, payout_cleared }

class TransactionModel {
  final String id;
  final String storeId;
  final String orderId;
  final double amount;
  final TransactionType type;
  final String status; // 'pending', 'completed'
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.storeId,
    required this.orderId,
    required this.amount,
    required this.type,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'orderId': orderId,
      'amount': amount,
      'type': type.name,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
