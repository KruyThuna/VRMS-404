import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../store.dart';
import '../../../localization/app_language.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/smart_image.dart';

/// Admin dialog to Post / Change / Update the Payment QR Code
/// used by clients in Storefront checkout and Admin payment modals.
class PostPaymentQrDialog extends StatefulWidget {
  final RentalStore store;
  final VoidCallback onSaved;

  const PostPaymentQrDialog({
    super.key,
    required this.store,
    required this.onSaved,
  });

  @override
  State<PostPaymentQrDialog> createState() => _PostPaymentQrDialogState();
}

class _PostPaymentQrDialogState extends State<PostPaymentQrDialog> {
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _qrUrlCtrl;
  late final TextEditingController _khqrDataCtrl;

  RentalStore get store => widget.store;
  bool get isKhmer => store.language == AppLanguage.khmer;

  final List<Map<String, String>> _presets = [
    {
      'label': 'ABA KHQR',
      'bank': 'ABA Bank',
      'account': 'DRIVELINE CAR RENTAL',
      'number': '000 892 112',
      'qrUrl': '',
    },
    {
      'label': 'Bakong NBC',
      'bank': 'Bakong',
      'account': 'DRIVELINE VRMS CO., LTD',
      'number': 'driveline_vrms@aba',
      'qrUrl': '',
    },
    {
      'label': 'Wing Bank',
      'bank': 'Wing Bank',
      'account': 'DRIVELINE RENTAL',
      'number': '098 765 432',
      'qrUrl': '',
    },
    {
      'label': 'ACLEDA',
      'bank': 'ACLEDA Bank',
      'account': 'DRIVELINE CAMBODIA',
      'number': '1234-5678-9012',
      'qrUrl': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    final cfg = store.agencyConfig;
    _bankNameCtrl = TextEditingController(text: cfg.bankName);
    _accountNameCtrl = TextEditingController(
      text: cfg.accountName.isNotEmpty ? cfg.accountName : cfg.companyName,
    );
    _accountNumberCtrl = TextEditingController(text: cfg.accountNumber);
    _qrUrlCtrl = TextEditingController(text: cfg.paymentQrUrl ?? '');
    _khqrDataCtrl = TextEditingController(text: cfg.khqrData ?? '');

    _qrUrlCtrl.addListener(() => setState(() {}));
    _accountNameCtrl.addListener(() => setState(() {}));
    _accountNumberCtrl.addListener(() => setState(() {}));
    _bankNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _qrUrlCtrl.dispose();
    _khqrDataCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> p) {
    setState(() {
      _bankNameCtrl.text = p['bank'] ?? '';
      _accountNameCtrl.text = p['account'] ?? '';
      _accountNumberCtrl.text = p['number'] ?? '';
      if (p['qrUrl'] != null && p['qrUrl']!.isNotEmpty) {
        _qrUrlCtrl.text = p['qrUrl']!;
      }
    });
  }

  Future<void> _save() async {
    final updated = store.agencyConfig.copyWith(
      bankName: _bankNameCtrl.text.trim().isEmpty ? 'ABA Bank' : _bankNameCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim().isEmpty
          ? store.agencyConfig.companyName
          : _accountNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim().isEmpty
          ? '000 892 112'
          : _accountNumberCtrl.text.trim(),
      paymentQrUrl: _qrUrlCtrl.text.trim().isEmpty ? null : _qrUrlCtrl.text.trim(),
      khqrData: _khqrDataCtrl.text.trim().isEmpty ? null : _khqrDataCtrl.text.trim(),
    );

    await store.updateAgencyConfig(updated);
    widget.onSaved();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.brandEmerald,
          content: Text(
            isKhmer
                ? 'បានបង្ហោះ និងផ្លាស់ប្តូរ QR Code ទូទាត់ជោគជ័យ!'
                : 'Payment QR Code successfully updated and posted!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomUrl = _qrUrlCtrl.text.trim().isNotEmpty;
    final currentBank = _bankNameCtrl.text.trim();
    final currentAccount = _accountNameCtrl.text.trim();
    final currentNumber = _accountNumberCtrl.text.trim();

    final dynamicPayload = _khqrDataCtrl.text.trim().isNotEmpty
        ? _khqrDataCtrl.text.trim()
        : 'https://checkout.bakong.nbc.gov.kh/qr?merchant=${Uri.encodeComponent(currentAccount)}&account=${Uri.encodeComponent(currentNumber)}&bank=${Uri.encodeComponent(currentBank)}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE12326).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFFE12326),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKhmer ? 'បង្ហោះ / ផ្លាស់ប្តូរ QR Code ទូទាត់' : 'Post / Change Payment QR Code',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isKhmer
                              ? 'កំណត់ QR Code ផ្លូវការដែលត្រូវបង្ហាញជូនអតិថិជនពេលបង់ប្រាក់'
                              : 'Set the official payment QR code displayed to clients at checkout',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Form Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preset Bank Selector Chips
                      Text(
                        isKhmer ? 'ជ្រើសរើសគំរូធនាគាររហ័ស:' : 'Quick Bank / Wallet Presets:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presets.map((p) {
                          final isSelected = currentBank.toLowerCase() == (p['bank'] ?? '').toLowerCase();
                          return ActionChip(
                            label: Text(p['label'] ?? ''),
                            avatar: Icon(
                              Icons.account_balance_rounded,
                              size: 14,
                              color: isSelected ? const Color(0xFFE12326) : Colors.grey.shade700,
                            ),
                            backgroundColor: isSelected
                                ? const Color(0xFFE12326).withAlpha(25)
                                : Colors.grey.shade100,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFFE12326) : Colors.black87,
                            ),
                            onPressed: () => _applyPreset(p),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Bank & Merchant Name Inputs
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKhmer ? 'ឈ្មោះធនាគារ / កាបូប' : 'Bank / Wallet Provider',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _bankNameCtrl,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    hintText: 'e.g. ABA Bank, Bakong',
                                    prefixIcon: const Icon(Icons.account_balance_rounded, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKhmer ? 'ឈ្មោះគណនី / ម្ចាស់' : 'Merchant / Account Name',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _accountNameCtrl,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    hintText: 'e.g. DRIVELINE RENTAL',
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Account Number / Bakong ID
                      Text(
                        isKhmer ? 'លេខគណនី / Bakong ID' : 'Account Number / Bakong ID',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _accountNumberCtrl,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: 'e.g. 000 892 112 or driveline@aba',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Custom QR Code Image URL
                      Text(
                        isKhmer ? 'តំណភ្ជាប់រូបភាព QR Code (URL)' : 'Custom QR Code Image URL (Optional)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isKhmer
                            ? 'ប្រសិនបើមាន អ្នកអាចបញ្ចូល URL នៃរូបភាព QR Code ផ្ទាល់ខ្លួនរបស់ហាង (ABA/Wing/Bakong)'
                            : 'Paste direct link to your shop QR code image (ABA PayWay / Wing / Bakong screenshot)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qrUrlCtrl,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: 'https://example.com/my-aba-qr.png',
                          prefixIcon: const Icon(Icons.image_outlined, size: 18),
                          suffixIcon: hasCustomUrl
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _qrUrlCtrl.clear(),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Interactive Live Preview Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF0F172A)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isKhmer ? 'ការមើលឃើញផ្ទាល់ (Live Preview)' : 'Customer View (Live Preview)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasCustomUrl ? Colors.blue.withAlpha(25) : Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hasCustomUrl
                                        ? (isKhmer ? 'រូបភាពផ្ទាល់ខ្លួន' : 'Custom Image')
                                        : (isKhmer ? 'បង្កើត QR ស្វ័យប្រវត្តិ' : 'Dynamic KHQR Vector'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasCustomUrl ? Colors.blue.shade700 : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mini Simulated Client Card
                            Container(
                              width: 220,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE12326).withAlpha(120), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE12326),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'KHQR',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            currentBank.isNotEmpty ? currentBank : 'Bakong',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentAccount.isNotEmpty ? currentAccount.toUpperCase() : 'DRIVELINE',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentNumber.isNotEmpty ? currentNumber : '000 892 112',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace'),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),

                                  // QR Code or Custom Image Display
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: hasCustomUrl
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: SmartImage(
                                              imageSource: _qrUrlCtrl.text.trim(),
                                              fit: BoxFit.contain,
                                              fallback: const Center(
                                                child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: QrImageView(
                                              data: dynamicPayload,
                                              version: QrVersions.auto,
                                              size: 130,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Color(0xFF0F172A),
                                              ),
                                              dataModuleStyle: const QrDataModuleStyle(
                                                dataModuleShape: QrDataModuleShape.square,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isKhmer ? 'បោះបង់' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isKhmer ? 'រក្សាទុក & បង្ហោះ QR Code' : 'Save & Post QR Code',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE12326),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

