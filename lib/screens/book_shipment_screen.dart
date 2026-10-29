import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/receipt_service.dart';
import 'package:intl/intl.dart';
import '../models/shipment.dart';
import '../services/shipment_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/shipment_repository.dart';

class BookShipmentScreen extends StatefulWidget {
  const BookShipmentScreen({super.key});

  @override
  State<BookShipmentScreen> createState() => _BookShipmentScreenState();
}

class _BookShipmentScreenState extends State<BookShipmentScreen> {
  int _step = 0;
  final PageController _pageController = PageController();

  // Form controllers
  final _itemNameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _senderNameCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  String _selectedType = 'Air Freight';
  String? _selectedBranch = 'Riyadh'; // Default to Riyadh or first branch
  final List<String> _types = [
    'Air Freight',
    'Sea Freight',
    'Land Freight',
    'Warehouse',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _itemNameCtrl.dispose();
    _weightCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _senderNameCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        24,
        24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_box_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book Shipment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step ${_step + 1} of 3',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Package', 'Route', 'Confirm'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isActive = _step == i;
          final isDone = _step > i;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.success
                              : isActive
                              ? AppColors.accent
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive || isDone
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? AppColors.accent
                              : isDone
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    width: 24,
                    color: isDone ? AppColors.success : AppColors.border,
                    margin: const EdgeInsets.only(bottom: 18),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard('Package Information', Icons.inventory_2_rounded, [
            _inputField(
              'Item Name',
              'e.g. Electronics',
              _itemNameCtrl,
              Icons.label_rounded,
            ),
            const SizedBox(height: 14),
            _inputField(
              'Weight (kg)',
              'e.g. 5.0',
              _weightCtrl,
              Icons.scale_rounded,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _label('Package Dimensions (cm)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _miniInputField('L', _lengthCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _miniInputField('W', _widthCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _miniInputField('H', _heightCtrl)),
              ],
            ),
            const SizedBox(height: 20),
            _label('Freight Type'),
            const SizedBox(height: 8),
            _typeSelector(),
          ]),
        ],
      ),
    );
  }

  Widget _miniInputField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  double _calculateVolumetricWeight() {
    final l = double.tryParse(_lengthCtrl.text) ?? 0;
    final w = double.tryParse(_widthCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    return (l * w * h) / 5000;
  }

  // Rates (SAR per kg)
  final Map<String, double> _rates = {
    'Air Freight': 30.0,
    'Sea Freight': 20.0,
    'Land Freight': 18.0,
    'Warehouse': 15.0,
  };

  Map<String, double> _calculatePriceDetails() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    final rate = _rates[_selectedType] ?? 0.0;
    
    // Calculate volumetric weight as a reference (L*W*H / 5000)
    final l = double.tryParse(_lengthCtrl.text) ?? 0;
    final w = double.tryParse(_widthCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final volWeight = (l * w * h) / 5000;
    
    final total = weight * rate;

    return {
      'total': total,
      'rate': rate,
      'volWeight': volWeight,
    };
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _sectionCard('Route Details', Icons.route_rounded, [
            _inputField(
              'From (Origin City)',
              'e.g. Dubai, UAE',
              _fromCtrl,
              Icons.flight_takeoff_rounded,
            ),
            const SizedBox(height: 14),
            _inputField(
              'To (Destination City)',
              'e.g. Karachi, Pakistan',
              _toCtrl,
              Icons.flight_land_rounded,
            ),
            const SizedBox(height: 14),
            _label('Select Nearest Branch'),
            const SizedBox(height: 8),
            _branchSelector(),
          ]),
          const SizedBox(height: 14),
          _sectionCard('Contact Details', Icons.contacts_rounded, [
            _inputField(
              'Sender Name',
              'Your name',
              _senderNameCtrl,
              Icons.person_rounded,
            ),
            const SizedBox(height: 14),
            _inputField(
              'Receiver Name',
              'Receiver\'s name',
              _receiverNameCtrl,
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _inputField(
              'Receiver Phone',
              '+92 3XX XXXXXXX',
              _receiverPhoneCtrl,
              Icons.phone_rounded,
              keyboard: TextInputType.phone,
            ),
          ]),
        ],
      ),
    );
  }

  void _validateAndNext() {
    if (_step == 0) {
      if (_itemNameCtrl.text.trim().isEmpty) {
        _showError('Item Name is required');
        return;
      }
      if (_weightCtrl.text.trim().isEmpty || (double.tryParse(_weightCtrl.text) ?? 0) <= 0) {
        _showError('Valid weight is required');
        return;
      }
      if (_lengthCtrl.text.trim().isEmpty || (double.tryParse(_lengthCtrl.text) ?? 0) <= 0) {
        _showError('Length is required');
        return;
      }
      if (_widthCtrl.text.trim().isEmpty || (double.tryParse(_widthCtrl.text) ?? 0) <= 0) {
        _showError('Width is required');
        return;
      }
      if (_heightCtrl.text.trim().isEmpty || (double.tryParse(_heightCtrl.text) ?? 0) <= 0) {
        _showError('Height is required');
        return;
      }
    } else if (_step == 1) {
      if (_fromCtrl.text.trim().isEmpty) {
        _showError('Origin City is required');
        return;
      }
      if (_toCtrl.text.trim().isEmpty) {
         _showError('Destination City is required');
        return;
      }
      if (_senderNameCtrl.text.trim().isEmpty) {
        _showError('Sender Name is required');
        return;
      }
      if (_receiverNameCtrl.text.trim().isEmpty) {
        _showError('Receiver Name is required');
        return;
      }
      if (_receiverPhoneCtrl.text.trim().isEmpty) {
        _showError('Receiver Contact is required');
        return;
      }
    }
    _nextStep();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _submitBooking() async {
    final authRepo = AuthRepository();
    final shipmentRepo = ShipmentRepository();
    
    final user = await authRepo.getCurrentUser();
    if (user == null) {
       _showError('Please login to continue');
       return;
    }

    final price = _calculatePriceDetails();
    final now = DateTime.now();
    final bookingId = 'SAB-${now.year}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );

    try {
      final shipment = Shipment(
        id: bookingId,
        trackingNumber: bookingId,
        itemName: _itemNameCtrl.text.trim(),
        origin: _fromCtrl.text.trim(),
        destination: _toCtrl.text.trim(),
        status: ShipmentStatus.booked,
        expectedDate: DateFormat('dd/MM/yyyy').format(now.add(const Duration(days: 7))),
        weight: double.tryParse(_weightCtrl.text) ?? 0.0,
        type: _selectedType,
        userEmail: user.email,
        branchId: _selectedBranch,
        steps: [
          TrackingStep(
            title: 'Booking Confirmed',
            subtitle: 'Shipment is pending pickup at ${_selectedBranch ?? 'Branch'}',
            time: DateFormat('dd MMM, HH:mm').format(now),
            isCompleted: true,
            isCurrent: true,
          ),
        ],
      );

      await shipmentRepo.createBooking(
        shipment,
        user,
        senderName: _senderNameCtrl.text.trim(),
        receiverName: _receiverNameCtrl.text.trim(),
        receiverPhone: _receiverPhoneCtrl.text.trim(),
        total: (price['total'] as num?)?.toDouble() ?? 0,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      
      // Generate receipt
      await ReceiptService.generateReceipt({
        ...shipment.toJson(),
        'total': price['total'],
        'date': DateFormat('dd MMM yyyy, HH:mm').format(now),
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Your booking ID is $bookingId', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => ReceiptService.generateReceipt({
                ...shipment.toJson(),
                'total': price['total'],
                'date': DateFormat('dd MMM yyyy, HH:mm').format(now),
              }),
              child: const Text('Download Receipt', style: TextStyle(color: AppColors.accent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
              },
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      _showError('Failed to save booking: $e');
    }
  }

  Widget _buildStep3() {
    final price = _calculatePriceDetails();
    final total = price['total'] ?? 0.0;
    final rate = price['rate'] ?? 0.0;

    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryRow('Item Name', _itemNameCtrl.text),
                _summaryRow('Type', _selectedType),
                _summaryRow('Weight', '${_weightCtrl.text} kg'),
                _summaryRow('Origin Hub', _selectedBranch ?? 'Main Office'),
                _summaryRow('From City', _fromCtrl.text),
                _summaryRow('To City', _toCtrl.text),
                _summaryRow('Sender', _senderNameCtrl.text),
                _summaryRow('Receiver', _receiverNameCtrl.text),
                _summaryRow('Receiver Phone', _receiverPhoneCtrl.text),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Price estimate
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Calculation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _priceRow('Weight', '${_weightCtrl.text} kg'),
                _priceRow('Rate', '${rate.toStringAsFixed(0)} SAR / kg'),
                const Divider(color: AppColors.divider, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} SAR',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _inputField(
    String label,
    String hint,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _branchSelector() {
    final branches = ['Riyadh', 'Jeddah', 'Dammam', 'Medina'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: branches.map((b) {
        final isSelected = _selectedBranch == b;
        return GestureDetector(
          onTap: () => setState(() => _selectedBranch = b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              b,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _types.map((t) {
        final isSelected = _selectedType == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppColors.orange : AppColors.border,
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0 && _step < 3)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_step > 0 && _step < 3) const SizedBox(width: 14),
          if (_step < 3)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _step == 2 ? _submitBooking : _validateAndNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _step == 2 ? 'Confirm Booking' : 'Continue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
