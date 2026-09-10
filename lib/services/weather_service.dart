import 'package:flutter/material.dart';
import '../../../services/currency_service.dart';

const _kBg = Color(0xff071722);
const _kCard1 = Color(0xff173747);
const _kCard2 = Color(0xff0b202c);
const _kGold = Color(0xffffd76a);

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  String _from = 'USD';
  String _to = 'EUR';
  final TextEditingController _amountCtrl =
      TextEditingController(text: '1');

  double? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _convert();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await CurrencyService.convert(
        from: _from,
        to: _to,
        amount: amount == 0 ? 1 : amount,
      );
      if (!mounted) return;
      setState(() {
        _result = value;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطا در دریافت نرخ آنلاین. اتصال اینترنت را بررسی کنید.';
        _loading = false;
      });
    }
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kGold),
          title: const Text(
            'تبدیل ارز آنلاین',
            style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'مبلغ',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onSubmitted: (_) => _convert(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _currencyPicker(isFrom: true)),
                        IconButton(
                          onPressed: _swap,
                          icon: const Icon(Icons.swap_horiz_rounded,
                              color: _kGold),
                        ),
                        Expanded(child: _currencyPicker(isFrom: false)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(color: _kGold),
                        ),
                      )
                    : _error != null
                        ? Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          )
                        : Column(
                            children: [
                              Text(
                                '${_amountCtrl.text} $_from ≈',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_result?.toStringAsFixed(3) ?? '-'} $_to',
                                style: const TextStyle(
                                  color: _kGold,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loading ? null : _convert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGold,
                  foregroundColor: _kBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'به‌روزرسانی نرخ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'نرخ‌ها بر اساس داده رسمی و آنلاین ارزهای جهانی است. توجه: ریال ایران به دلیل نبود بازار رسمی جهانی در این سرویس پشتیبانی نمی‌شود.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11.5,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCard1, _kCard2],
        ),
        border: Border.all(color: _kGold.withOpacity(0.4)),
      ),
      child: child,
    );
  }

  Widget _currencyPicker({required bool isFrom}) {
    final current = isFrom ? _from : _to;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        dropdownColor: _kCard2,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: _kGold),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        items: CurrencyService.supportedCurrencies
            .map(
              (c) => DropdownMenuItem(
                value: c['code'],
                child: Text('${c['flag']} ${c['code']}'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (isFrom) {
              _from = value;
            } else {
              _to = value;
            }
          });
          _convert();
        },
      ),
    );
  }
}
