class Payment {
  final String id;
  final double amount;
  final String method;
  final String status;

  Payment({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
  });
}