import 'package:flutter/material.dart';
import '../Data Models/address.dart';
import '../services/cart_service.dart';
import '../widgets/checkout/payment_details_section.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final Address selectedAddress;
  final List<Map<String, dynamic>> payloadCart;
  final String clientOrderId;
  final VoidCallback onBackToCheckout;
  final VoidCallback onPayNow;
  final bool isProcessing;

  const PaymentConfirmationPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
    required this.payloadCart,
    required this.clientOrderId,
    required this.onBackToCheckout,
    required this.onPayNow,
    required this.isProcessing,
  }) : super(key: key);

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
        backgroundColor:Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToCheckout,
        ),
      ),
      body: PaymentDetailsSection(
        cartItems: widget.cartItems,
        totalAmount: widget.totalAmount,
        selectedAddress: widget.selectedAddress,
        isProcessing: widget.isProcessing,
        onPayNow: widget.onPayNow,
      ),
    );
  }
}