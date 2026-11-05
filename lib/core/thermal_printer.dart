import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'config.dart';

class ThermalPrinterException implements Exception {
  final String message;
  ThermalPrinterException(this.message);
  @override String toString() => message;
}

class ThermalPrinterService {
  static Future<List<BluetoothInfo>> pairedPrinters() async {
    await _ensureBluetoothPermission();
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) throw ThermalPrinterException('Turn on Bluetooth and pair the thermal printer first.');
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<void> _ensureBluetoothPermission() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    if (!connect.isGranted && !scan.isGranted) {
      throw ThermalPrinterException('Bluetooth permission is required to print receipts.');
    }
  }

  static Future<void> printReceipt({
    required BluetoothInfo printer,
    required Map<String, dynamic> receipt,
    required String collector,
  }) async {
    await _ensureBluetoothPermission();
    var connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      connected = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAdress);
    }
    if (!connected) throw ThermalPrinterException('Unable to connect to ${printer.name}. Pair it in phone Bluetooth settings and retry.');

    final profile = await CapabilityProfile.load();
    final g = Generator(PaperSize.mm58, profile);
    final p = receipt['payload'] is Map ? Map<String,dynamic>.from(receipt['payload']) : <String,dynamic>{};
    final status = '${receipt['status'] ?? 'Pending'}';
    final isUpgrade = p['package_upgrade'] == true;
    final cents = int.tryParse('${p['amount'] ?? 0}') ?? 0;
    final balance = int.tryParse('${receipt['provisional_balance'] ?? 0}') ?? 0;
    final totalDueBefore = int.tryParse('${receipt['total_due_before'] ?? p['total_due_before'] ?? (balance + cents)}') ?? (balance + cents);
    final previousBalance = int.tryParse('${receipt['previous_balance'] ?? p['previous_balance'] ?? 0}') ?? 0;
    final previousBalanceMonth = '${receipt['previous_balance_month'] ?? p['previous_balance_month'] ?? ''}'.trim();
    final previousPending = int.tryParse('${receipt['previous_pending'] ?? p['previous_pending'] ?? 0}') ?? 0;
    final currentBill = int.tryParse('${receipt['current_bill'] ?? p['current_bill'] ?? (totalDueBefore - previousBalance)}') ?? (totalDueBefore - previousBalance);
    String rs(int v) => 'Rs ${(v / 100).toStringAsFixed(v % 100 == 0 ? 0 : 2)}';

    String titleCase(dynamic value) {
      final s = '${value ?? ''}'.trim();
      if (s.isEmpty) return '';
      return s
          .split(RegExp(r'\s+'))
          .map((word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
          .join(' ');
    }

    String displayDate(dynamic value) {
      final raw = '${value ?? ''}'.trim();
      if (raw.isEmpty) return '';
      final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(datePart);
      if (m != null) {
        return '${m.group(3)}-${m.group(2)}-${m.group(1)}';
      }
      return raw;
    }

    String displayBillMonth(dynamic value) {
      final raw = '${value ?? ''}'.trim();
      if (raw.isEmpty) return '';
      final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
      if (m == null) return raw;
      final year = m.group(1)!;
      final month = int.tryParse(m.group(2)!) ?? 0;
      const names = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      if (month < 1 || month > 12) return raw;
      return '${names[month]} $year';
    }
    final bytes = <int>[];
    bytes.addAll(g.reset());
    bytes.addAll(g.text('KHALID NETWORKS', styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2)));
    bytes.addAll(g.text(AppConfig.companyPhone, styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.text(isUpgrade ? 'PACKAGE CHANGED' : 'INTERNET BILL COLLECTION RECEIPT', styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.hr());
    bytes.addAll(g.text('Receipt: ${receipt['receipt_no'] ?? ''}'));
    bytes.addAll(g.text('Collector: $collector'));
    bytes.addAll(g.text('Date: ${displayDate(p['date'] ?? receipt['created_at'])}'));
    bytes.addAll(g.hr());
    bytes.addAll(g.text('User: ${titleCase(receipt['customer_name'] ?? p['name'])}', styles: const PosStyles(bold: true)));
    bytes.addAll(g.text('Village: ${receipt['village'] ?? ''}'));
    bytes.addAll(g.text('Bill month: ${displayBillMonth(p['month'])}'));
    if (isUpgrade) {
      bytes.addAll(g.text('New Package: ${p['new_package'] ?? p['package_name'] ?? ''}', styles: const PosStyles(bold: true)));
    }
    bytes.addAll(g.text('Method: ${p['method'] ?? 'Cash'}'));
    final referenceText = '${p['reference'] ?? ''}'.trim();
    if (referenceText.isNotEmpty) {
      bytes.addAll(g.text('Reference: $referenceText'));
    }
    bytes.addAll(g.hr());
    bytes.addAll(g.feed(1));
    bytes.addAll(g.text('Previous Balance: ${rs(previousBalance)}'));
    if (previousBalance > 0 && previousBalanceMonth.isNotEmpty) {
      bytes.addAll(g.text('Previous Month: ${displayBillMonth(previousBalanceMonth)}'));
    }
    if (previousPending > 0) {
      bytes.addAll(g.text('Previous Pending: ${rs(previousPending)}'));
    }
    bytes.addAll(g.text('Current Bill: ${rs(currentBill)}'));
    bytes.addAll(g.text('Total Due: ${rs(totalDueBefore)}'));
    bytes.addAll(g.text('AMOUNT PAID: ${rs(cents)}', styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2)));
    bytes.addAll(g.text('Remaining: ${rs(balance)}'));
    bytes.addAll(g.feed(1));
    bytes.addAll(g.hr());
    bytes.addAll(g.text('For complaints/support:', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text('05828440008', styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.feed(1));
    bytes.addAll(g.text('Thank you for your payment.', styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.feed(3));
    final ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) throw ThermalPrinterException('Printer did not accept the receipt. Check paper and Bluetooth connection.');
  }
}
