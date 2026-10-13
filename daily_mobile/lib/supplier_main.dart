import 'package:flutter/material.dart';
import 'screens/supplier/supplier_login_screen.dart';

void main() {
  runApp(const SupplierPreviewApp());
}

class SupplierPreviewApp extends StatelessWidget {
  const SupplierPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DAILY Supplier Preview',
      home: SupplierLoginScreen(),
    );
  }
}