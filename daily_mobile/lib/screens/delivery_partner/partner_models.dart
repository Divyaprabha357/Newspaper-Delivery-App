class RouteCustomer {
  final String number;
  final String name;
  final String address;
  final String area;
  final String time;
  final List<String> newspapers;
  final String instructions;
  final int? deliveryId;
  final int? assignmentId;
  final int? customerId;
  final List<int> itemIds;
  final String? deliveryStatus;

  const RouteCustomer({
    required this.number,
    required this.name,
    required this.address,
    required this.area,
    required this.time,
    required this.newspapers,
    required this.instructions,
    this.deliveryId,
    this.assignmentId,
    this.customerId,
    this.itemIds = const [],
    this.deliveryStatus,
  });
}
