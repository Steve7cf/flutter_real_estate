import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real_estate/models/property.dart';
import 'dart:io';
import 'package:real_estate/screens/property_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Added for jsonEncode and jsonDecode

class PropertyPage extends StatefulWidget {
  final Property property;

  const PropertyPage({super.key, required this.property});

  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  bool _isPaid = false;
  bool _isLoadingPayment = false;

  @override
  void initState() {
    super.initState();
    _checkPaidStatus();
  }

  Future<void> _checkPaidStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final paidList = prefs.getStringList('paid_properties') ?? [];
    setState(() {
      _isPaid = paidList.contains(widget.property.id);
    });
  }

  Future<void> _showPaymentOptions() async {
    final method = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.95 * 255).toInt()),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
                backgroundBlendMode: BlendMode.overlay,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(top: 12, bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your preferred way to pay for this property.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const Text(
                          'Mobile Money',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentTileWithDialog(
                          name: 'Vodacom M-Pesa',
                          asset: 'assets/vodacom.png',
                          color: Colors.red[800]!,
                          description: 'Fast and secure mobile payments.',
                          isMobileMoney: true,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'Tigo Pesa',
                          asset: 'assets/yas.png',
                          color: Colors.blue[700]!,
                          description: 'Pay easily with your Tigo line.',
                          isMobileMoney: true,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'Airtel Money',
                          asset: 'assets/airtel.png',
                          color: Colors.red[700]!,
                          description: 'Use Airtel Money for instant payment.',
                          isMobileMoney: true,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'Halopesa',
                          asset: 'assets/halotel.png',
                          color: Colors.orange[700]!,
                          description: 'Halotel mobile money service.',
                          isMobileMoney: true,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Banks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentTileWithDialog(
                          name: 'CRDB Bank',
                          asset: 'assets/crdb.png',
                          color: Colors.green[800]!,
                          description: 'Pay with your CRDB account.',
                          isMobileMoney: false,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'NMB Bank',
                          asset: 'assets/nmb.jpg',
                          color: Colors.blue[900]!,
                          description: 'Pay with your NMB account.',
                          isMobileMoney: false,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'NBC Bank',
                          asset: 'assets/nbc.jpg',
                          color: Colors.indigo[900]!,
                          description: 'Pay with your NBC account.',
                          isMobileMoney: false,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'Selcom',
                          asset: 'assets/selcom.png',
                          color: Colors.deepPurple,
                          description: 'Pay via Selcom network.',
                          isMobileMoney: false,
                        ),
                        _buildPaymentTileWithDialog(
                          name: 'TTCL Pesa',
                          asset: 'assets/ttcl.png',
                          color: Colors.teal[700]!,
                          description: 'TTCL mobile money service.',
                          isMobileMoney: true,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (method != null) {
      if (method['isMobileMoney'] == 'true') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final phone = await _showPhoneNumberDialog(
              provider: method['name']!,
              asset: method['asset']!,
            );
            if (phone != null && phone.isNotEmpty) {
              final confirmed = await _showPaymentPasswordDialog(
                provider: method['name']!,
                asset: method['asset']!,
                phone: phone,
                amount: widget.property.price.startsWith('Tsh')
                    ? widget.property.price
                    : 'Tsh ${widget.property.price}',
              );
              if (confirmed == true) {
                _processPayment('${method['name']} ($phone)');
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not show phone dialog: $e')),
              );
            }
          }
        });
      } else {
        _processPayment(method['name']!);
      }
    }
  }

  Future<void> _processPayment(String method) async {
    setState(() => _isLoadingPayment = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text('Paying with $method...')),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final paidList = prefs.getStringList('paid_properties') ?? [];
    if (!paidList.contains(widget.property.id)) {
      paidList.add(widget.property.id);
      await prefs.setStringList('paid_properties', paidList);
    }
    // --- New: Save bought property with payment details ---
    final boughtList = prefs.getStringList('bought_properties') ?? [];
    final now = DateTime.now();
    final paymentDetails = {
      ...widget.property.toJson(),
      'payment_method': method,
      'payment_time': now.toIso8601String(),
    };
    boughtList.add(jsonEncode(paymentDetails));
    await prefs.setStringList('bought_properties', boughtList);
    // --- New: Remove from available properties if present ---
    final allProps = prefs.getStringList('all_properties') ?? [];
    allProps.removeWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == widget.property.id;
    });
    await prefs.setStringList('all_properties', allProps);
    setState(() {
      _isPaid = true;
      _isLoadingPayment = false;
    });
    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text(
            'You have successfully paid with $method. The property is now yours!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.of(context).pop(true); // Pop this page and signal refresh
    }
  }

  Widget _buildPaymentTileWithDialog({
    required String name,
    required String asset,
    required Color color,
    required String description,
    required bool isMobileMoney,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pop(context, {
            'name': name,
            'asset': asset,
            'isMobileMoney': isMobileMoney.toString(),
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    (color.r * 255.0).round() & 0xff,
                    (color.g * 255.0).round() & 0xff,
                    (color.b * 255.0).round() & 0xff,
                    0.13,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.account_balance_wallet, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showPhoneNumberDialog({
    required String provider,
    required String asset,
  }) async {
    final controller = TextEditingController();
    String? errorText;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Image.asset(
                    asset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Enter $provider Number')),
                ],
              ),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.phone),
                ),
                maxLength: 15,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty || value.length < 10) {
                      setState(() => errorText = 'Enter a valid phone number');
                    } else {
                      Navigator.pop(context, value);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showPaymentPasswordDialog({
    required String provider,
    required String asset,
    required String phone,
    required String amount,
  }) async {
    final controller = TextEditingController();
    String? errorText;
    bool obscure = true;
    bool isLoading = false;
    bool showSuccess = false;
    int attempts = 0;
    bool locked = false;
    DateTime? lockEnd;
    Color accentColor = _getProviderColor(provider);
    String maskedPhone = phone.length > 3
        ? phone.replaceRange(2, phone.length - 3, '*' * (phone.length - 5))
        : phone;
    String passwordStrength = '';
    void clearSensitive() {
      controller.clear();
      errorText = null;
      obscure = true;
      isLoading = false;
      showSuccess = false;
      passwordStrength = '';
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onPasswordChanged(String value) {
              if (value.length < 4) {
                setState(() => passwordStrength = 'Weak');
              } else {
                setState(() => passwordStrength = 'Strong');
              }
            }

            Future<void> handlePay() async {
              if (locked) return;
              final value = controller.text.trim();
              if (value.isEmpty || value.length < 4) {
                setState(() {
                  errorText = 'Enter a valid password';
                });
                // Shake effect
                await Future.delayed(const Duration(milliseconds: 100));
                setState(() {});
                attempts++;
                if (attempts >= 3) {
                  locked = true;
                  lockEnd = DateTime.now().add(const Duration(seconds: 30));
                  setState(() {
                    errorText = 'Too many attempts. Try again in 30 seconds.';
                  });
                  Future.delayed(const Duration(seconds: 30), () {
                    if (Navigator.of(context).canPop()) {
                      setState(() {
                        locked = false;
                        attempts = 0;
                        errorText = null;
                      });
                    }
                  });
                }
                return;
              }
              setState(() {
                isLoading = true;
                errorText = null;
              });
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                isLoading = false;
                showSuccess = true;
              });
              await Future.delayed(const Duration(seconds: 1));
              clearSensitive();
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context, true);
              }
            }

            Future<void> handleCancel() async {
              if (isLoading) return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Payment?'),
                  content: const Text(
                    'Are you sure you want to cancel this payment?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true && Navigator.of(context).canPop()) {
                clearSensitive();
                Navigator.pop(context, false);
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Image.asset(
                    asset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Confirm Payment',
                      style: TextStyle(color: accentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Why is password needed?',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Payment Security'),
                          content: const Text(
                            'Your mobile money password is required to authorize the payment securely. It is never stored.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SingleChildScrollView(
                  child: showSuccess
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: accentColor,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Payment Successful!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Provider: $provider'),
                            Text('Number: $maskedPhone'),
                            Text(
                              'Amount:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              amount,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              obscureText: obscure,
                              enableInteractiveSelection:
                                  false, // disables clipboard
                              enableSuggestions: false,
                              autocorrect: false,
                              onChanged: onPasswordChanged,
                              decoration: InputDecoration(
                                labelText: 'Mobile Money Password',
                                errorText: errorText,
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                ),
                              ),
                              maxLength: 12,
                            ),
                            if (passwordStrength.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 2,
                                ),
                                child: Text(
                                  'Strength: $passwordStrength',
                                  style: TextStyle(
                                    color: passwordStrength == 'Strong'
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (locked && lockEnd != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Locked. Try again at ${lockEnd!.hour.toString().padLeft(2, '0')}:${lockEnd!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              actions: showSuccess
                  ? []
                  : [
                      TextButton(
                        onPressed: handleCancel,
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                        ),
                        onPressed: isLoading || locked ? null : handlePay,
                        child: const Text('Pay'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'vodacom m-pesa':
        return Colors.red[800]!;
      case 'tigo pesa':
        return Colors.blue[700]!;
      case 'airtel money':
        return Colors.red[700]!;
      case 'halopesa':
        return Colors.orange[700]!;
      case 'ttcl pesa':
        return Colors.teal[700]!;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final theme = Theme.of(context);
    String postedDate = property.scrapedAt.isNotEmpty
        ? property.scrapedAt.split('T').first
        : '';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  property.images.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: property.images.length,
                          itemBuilder: (context, index) {
                            final img = property.images[index];
                            if (img.startsWith('/') ||
                                img.startsWith('file://')) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Image.file(
                                  File(img),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 100),
                                ),
                              );
                            } else {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error, size: 100),
                                ),
                              );
                            }
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          height: 320,
                          width: double.infinity,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 100,
                          ),
                        ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(128),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                "4.9",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(128),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            property.type != 'N/A' ? property.type : 'Property',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
            actions: [
              // Removed like and upload icons
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.price.startsWith('Tsh')
                        ? property.price
                        : 'Tsh ${property.price}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.deepOrangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Property Description",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(property.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.king_bed_outlined),
                      const SizedBox(width: 4),
                      Text(property.bedrooms),
                      const SizedBox(width: 16),
                      const Icon(Icons.bathtub),
                      const SizedBox(width: 4),
                      Text(property.bathrooms),
                      const SizedBox(width: 16),
                      const Icon(Icons.square_foot),
                      const SizedBox(width: 4),
                      Text(property.area),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 4),
                      Text(property.type),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        postedDate.isNotEmpty ? 'Posted on $postedDate' : '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 340,
        height: 60,
        child: _isPaid
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PropertyChatScreen(property: property),
                    ),
                  );
                },
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                label: const Text(
                  'Send Message',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : FloatingActionButton.extended(
                onPressed: _isLoadingPayment ? null : _showPaymentOptions,
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                label: _isLoadingPayment
                    ? const Text(
                        'Processing...',
                        style: TextStyle(fontSize: 18),
                      )
                    : const Text('Buy', style: TextStyle(fontSize: 18)),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
