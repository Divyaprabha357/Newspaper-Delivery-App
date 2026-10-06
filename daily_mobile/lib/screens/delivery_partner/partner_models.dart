class RouteCustomer {
  final String number;
  final String name;
  final String address;
  final String area;
  final String time;
  final List<String> newspapers;
  final String instructions;

  const RouteCustomer({
    required this.number,
    required this.name,
    required this.address,
    required this.area,
    required this.time,
    required this.newspapers,
    required this.instructions,
  });
}

const partnerCustomers = [
  RouteCustomer(
    number: '01',
    name: 'Aarav Sharma',
    address: '12 Shivaji Park Road',
    area: 'Dadar West, Mumbai — 400028',
    time: '7:00 AM',
    newspapers: ['The Times of India', 'Hindustan Times'],
    instructions: 'Leave the newspaper near the main door.',
  ),
  RouteCustomer(
    number: '02',
    name: 'Priya Deshmukh',
    address: '45 Tilak Road',
    area: 'Dadar West, Mumbai — 400028',
    time: '7:15 AM',
    newspapers: ['The Hindu'],
    instructions: 'Please place it in the newspaper holder.',
  ),
  RouteCustomer(
    number: '03',
    name: 'Vikram Joshi',
    address: '8 Senapati Bapat Marg',
    area: 'Mahim, Mumbai — 400016',
    time: '7:30 AM',
    newspapers: ['Indian Express', 'The Times of India'],
    instructions: 'Ring the bell once.',
  ),
];
