import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../Data Models/address.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import '../widgets/checkout/address_form.dart';
import '../widgets/checkout/order_summary_section.dart';
import '../widgets/checkout/address_selection_section.dart';
import 'payment_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  const CheckoutPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Address> addresses = [];
  bool loadingAddresses = true;
  String? addressError;
  String? selectedAddressId;

  // Payment states
  late Razorpay _razorpay;
  bool _processingPayment = false;

  // Variables preserved across payment lifecycle
  String _currentClientOrderId = '';
  String? _currentRazorpayOrderId;
  late List<Map<String, dynamic>> _currentPayloadCart;
  late Map<String, dynamic> _currentSelectedAddressMap;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadAddresses();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      loadingAddresses = true;
      addressError = null;
    });
    try {
      final list = await AddressService.fetchAddresses();
      setState(() {
        addresses = list;
        if (selectedAddressId == null && addresses.isNotEmpty) {
          selectedAddressId = addresses.first.id;
        }
      });
    } catch (e) {
      setState(() => addressError = e.toString());
    } finally {
      setState(() => loadingAddresses = false);
    }
  }

  double get _total {
    double t = 0;
    for (final c in widget.cartItems) {
      t += (c.product?.mrp ?? 0) * c.count;
    }
    return t;
  }

  Future<void> _openAddEdit({Address? edit}) async {
    final result = await showModalBottomSheet<Address?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddressForm(address: edit),
      ),
    );

    if (result == null) return;
    await _handleAddressResult(result, edit);
  }

  Future<void> _handleAddressResult(Address result, Address? edit) async {
    try {
      if (edit != null && edit.id != null) {
        final updated = await AddressService.updateAddress(edit.id!, result);
        final idx = addresses.indexWhere((a) => a.id == edit.id);
        if (idx >= 0) setState(() => addresses[idx] = updated);
        setState(() => selectedAddressId = updated.id);
        _showSnackBar('Address updated');
      } else {
        final created = await AddressService.createAddress(result);
        setState(() {
          addresses.insert(0, created);
          selectedAddressId = created.id;
        });
        _showSnackBar('Address created');
      }
    } catch (e) {
      _showSnackBar('Operation failed: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToPaymentConfirmation() {
    if (selectedAddressId == null) {
      _showSnackBar('Please select or add an address', isError: true);
      return;
    }

    // Build payload cart
    final List<Map<String, dynamic>> payloadCart = [];
    for (final c in widget.cartItems) {
      final productId = c.productId ?? c.product?.id ?? c.rawId;

      if (productId == null || productId.isEmpty) {
        _showSnackBar(
          'Some items are missing product information.',
          isError: true,
        );
        return;
      }

      final price = c.product?.mrp ?? 0;
      final itemMap = {
        'id': productId,
        'productId': productId,
        'title': c.product?.title ?? 'Item',
        'price': price,
        'quantity': c.count,
      };
      payloadCart.add(itemMap);
    }

    _currentPayloadCart = payloadCart;
    final chosen = addresses.firstWhere((a) => a.id == selectedAddressId!);
    _currentSelectedAddressMap = {'id': chosen.id};
    _currentClientOrderId = 'o${DateTime.now().millisecondsSinceEpoch}';

    // Navigate to payment confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationPage(
          cartItems: widget.cartItems,
          totalAmount: _total,
          selectedAddress: chosen,
          payloadCart: _currentPayloadCart,
          clientOrderId: _currentClientOrderId,
          onBackToCheckout: () => Navigator.pop(context),
          onPayNow: _onPayNow,
          isProcessing: _processingPayment,
        ),
      ),
    );
  }

  Future<void> _onPayNow() async {
    if (_processingPayment) return;

    setState(() => _processingPayment = true);

    try {
      debugPrint('🔄 Starting payment process...');
      debugPrint('💰 Amount: $_total');
      debugPrint('📦 Order ID: $_currentClientOrderId');

      // 1) Create Razorpay order on backend
      final createResp = await PaymentService.createPaymentOrder(
        amount: _total,
        orderId: _currentClientOrderId,
      );

      debugPrint('✅ Backend response: $createResp');

      final razorpayOrderId = createResp['razorpayOrderId']?.toString();
      final razorKey = createResp['key']?.toString() ?? 'rzp_test_YourTestKey';

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        throw Exception('Backend did not return razorpay order id. Response: $createResp');
      }

      debugPrint('🎯 Razorpay Order ID: $razorpayOrderId');
      debugPrint('🔑 Razorpay Key: $razorKey');

      // 2) Open Razorpay checkout
      final selectedAddress = addresses.firstWhere((a) => a.id == selectedAddressId!);

      final options = {
        'key': razorKey,
        'amount': (_total * 100).toInt(), // in paise
        'name': 'Your Shop',
        'description': 'Order #$_currentClientOrderId',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': selectedAddress.phoneNumber ?? '9999999999',
          'email': selectedAddress.email ?? 'customer@example.com',
        },
        'theme': {
          'color': '#F37254',
          'hide_topbar': false
        },
      };

      debugPrint('🎪 Opening Razorpay with options: ${jsonEncode(options)}');

      // Open Razorpay payment gateway
      _razorpay.open(options);

    } catch (e, st) {
      debugPrint('❌ ERROR in payment process: $e');
      debugPrint('📋 Stack trace: $st');

      String errorMessage = 'Payment initialization failed';

      if (e.toString().contains('404')) {
        errorMessage = 'Payment service not available (404). Please check if backend is running.';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check if backend is running.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else {
        errorMessage = 'Payment failed: $e';
      }

      _showSnackBar(errorMessage, isError: true);
      setState(() => _processingPayment = false);
    }
  }

  // Razorpay callbacks
  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    debugPrint('Razorpay success: order=${response.orderId}, payment=${response.paymentId}');
    try {
      final verifyResp = await PaymentService.verifyPayment(
        razorpayOrderId: response.orderId ?? _currentRazorpayOrderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        orderId: _currentClientOrderId,
        selectedAddress: _currentSelectedAddressMap,
        cartItems: _currentPayloadCart,
      );

      debugPrint('Payment verification response: $verifyResp');
      _showSnackBar('Payment successful and order placed');

      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Verify payment failed: $e');
      _showSnackBar('Payment succeeded but order placement failed: $e', isError: true);
      setState(() => _processingPayment = false);
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    debugPrint('Razorpay error: ${response.message}');
    _showSnackBar('Payment failed: ${response.message}', isError: true);
    setState(() => _processingPayment = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    _showSnackBar('External wallet selected: ${response.walletName}');
    setState(() => _processingPayment = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAddresses,
            tooltip: 'Refresh addresses',
          ),
        ],
      ),
      body: _buildCheckoutView(),
    );
  }

  Widget _buildCheckoutView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Section
                AddressSelectionSection(
                  addresses: addresses,
                  loadingAddresses: loadingAddresses,
                  addressError: addressError,
                  selectedAddressId: selectedAddressId,
                  onAddressSelected: (String? id) => setState(() => selectedAddressId = id),
                  onAddAddress: () => _openAddEdit(),
                  onEditAddress: (Address address) => _openAddEdit(edit: address),
                  onAddressesUpdated: (List<Address> updatedAddresses) {
                    setState(() {
                      addresses = updatedAddresses;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Order Summary Section
                OrderSummarySection(
                  cartItems: widget.cartItems,
                  total: _total,
                ),
              ],
            ),
          ),
        ),

        // Continue to Payment Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Total Amount
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${_total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Continue to Payment Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _navigateToPaymentConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue to Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}