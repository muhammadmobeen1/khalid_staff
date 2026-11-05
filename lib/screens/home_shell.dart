import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../core/app_controller.dart';
import '../core/api_client.dart';
import '../core/helpers.dart';
import '../core/thermal_printer.dart';
import '../widgets/ui.dart';
import '../core/config.dart';

String shortMonthLabel(dynamic value) {
  final raw = '${value ?? ''}'.trim();
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
  if (m == null) return raw;
  final month = int.tryParse(m.group(2)!) ?? 0;
  const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) return raw;
  return '${names[month]} ${m.group(1)}';
}

class HomeShell extends StatefulWidget {
  final AppController controller;
  const HomeShell({super.key, required this.controller});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: widget.controller),
      BillsPage(controller: widget.controller),
      ConnectionPage(controller: widget.controller),
      ComplaintsPage(controller: widget.controller),
      ProfilePage(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.person_add_alt_1_outlined), selectedIcon: Icon(Icons.person_add_alt_1), label: 'New'),
          NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppController controller;
  final List<Widget> actions;
  const PageHeader({super.key, required this.title, required this.subtitle, required this.controller, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Color(0xFF71809B))),
      ])),
      ...actions,
    ]),
  );
}

class DashboardPage extends StatefulWidget {
  final AppController controller;
  const DashboardPage({super.key, required this.controller});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool dutyBusy = false;
  String? dutyMessage;

  Future<void> toggleDuty() async {
    setState(() { dutyBusy = true; dutyMessage = null; });
    try {
      if (widget.controller.tracking || widget.controller.sharing) {
        await widget.controller.stopDuty();
        dutyMessage = 'Duty stopped. Location sharing is off.';
      } else {
        await widget.controller.startDuty();
        dutyMessage = 'Duty started. Your latest location is being shared.';
      }
    } on ApiException catch (e) {
      dutyMessage = e.message;
    } catch (_) {
      dutyMessage = 'Unable to update duty status.';
    } finally {
      if (mounted) setState(() => dutyBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.profile;
    final latest = c.payload?['latest'];
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [navy, Color(0xFF123A76)]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
          child: Row(children: [
            _Avatar(controller: c, size: 58),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('STAFF WORKSPACE', style: TextStyle(color: Color(0xFFA9C4F7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const SizedBox(height: 3),
              Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              Text('${p['role'] ?? 'Staff'}', style: const TextStyle(color: Color(0xFFD4E0F5))),
            ])),
            IconButton(onPressed: c.refresh, icon: const Icon(Icons.refresh, color: Colors.white)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              color: const Color(0xFFF2F7FF),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: (c.tracking || c.sharing) ? green.withOpacity(.14) : blue.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.location_on_rounded, color: (c.tracking || c.sharing) ? green : blue)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((c.tracking || c.sharing) ? 'Duty Active' : 'Duty & Location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
                    Text((c.tracking || c.sharing) ? 'Location sharing is enabled.' : 'Start duty to share your work location.', style: const TextStyle(color: Color(0xFF71809B))),
                  ])),
                ]),
                if (latest is Map) ...[
                  const SizedBox(height: 10),
                  Text('Last location: ${latest['recorded_at'] ?? '—'}', style: const TextStyle(fontSize: 12, color: Color(0xFF71809B))),
                ],
                if (dutyMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(dutyMessage!, style: const TextStyle(fontWeight: FontWeight.w600, color: navy)),
                ],
                const SizedBox(height: 14),
                SizedBox(height: 52, child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: (c.tracking || c.sharing) ? red : green),
                  onPressed: dutyBusy ? null : toggleDuty,
                  icon: dutyBusy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon((c.tracking || c.sharing) ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded),
                  label: Text((c.tracking || c.sharing) ? 'Stop Duty' : 'Start Duty'),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                StatCard(label: 'Assigned villages', value: '${c.villages.length}', icon: Icons.location_city_rounded, accent: blue),
                StatCard(label: 'Unpaid bills', value: '${c.bills.length}', icon: Icons.receipt_long_rounded, accent: red),
                StatCard(label: 'Awaiting approval', value: money(c.summary['pending_amount']), icon: Icons.hourglass_top_rounded, accent: purple),
                StatCard(label: 'Approved today', value: money(c.summary['approved_today']), icon: Icons.verified_rounded, accent: green),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Assigned Villages', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 10),
            AppCard(child: Wrap(spacing: 8, runSpacing: 8, children: c.villages.isEmpty ? [const Text('No villages assigned.', style: TextStyle(color: Color(0xFF71809B)))] : c.villages.map((v) => Chip(label: Text('${v['name']}'), avatar: const Icon(Icons.place_outlined, size: 17))).toList())),
            const SizedBox(height: 80),
          ]),
        ),
      ]),
    );
  }
}

class BillsPage extends StatefulWidget {
  final AppController controller;
  const BillsPage({super.key, required this.controller});
  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final bills = widget.controller.bills.where((b) => query.isEmpty || '${b['name']} ${b['phone']} ${b['village']} ${b['id']}'.toLowerCase().contains(query.toLowerCase())).toList();
    return Column(children: [
      PageHeader(title: 'Collect Bills', subtitle: 'Submit customer payments and print provisional receipts.', controller: widget.controller, actions: [IconButton(tooltip: 'Receipt history', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionHistoryPage(controller: widget.controller))), icon: const Icon(Icons.history_rounded)), IconButton(onPressed: widget.controller.refresh, icon: const Icon(Icons.refresh))]),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(onChanged: (v) => setState(() => query = v), decoration: fieldDecoration('Search bills', hint: 'Customer, phone, village or bill #', icon: Icons.search))),
      const SizedBox(height: 10),
      Expanded(child: bills.isEmpty ? const EmptyState(title: 'No unpaid bills', message: 'No unpaid bills match your assigned villages or current search.') : RefreshIndicator(
        onRefresh: widget.controller.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          itemCount: bills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final b = bills[i];
            final amount = int.tryParse('${b['amount'] ?? 0}') ?? 0;
            final paid = int.tryParse('${b['paid'] ?? 0}') ?? 0;
            final totalDue = int.tryParse('${b['total_due'] ?? 0}') ?? 0;
            return AppCard(
              onTap: () async { final receipt = await showModalBottomSheet<Map<String,dynamic>>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => CollectionSheet(controller: widget.controller, bill: b)); if (receipt != null && context.mounted) { await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ProvisionalReceiptSheet(controller: widget.controller, receipt: receipt)); } },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('${b['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: navy))), Text(money(totalDue > 0 ? totalDue : (amount - paid)), style: const TextStyle(color: red, fontWeight: FontWeight.w900))]),
                const SizedBox(height: 5),
                Text('${b['village']} • Bill #${b['id']} • ${b['month']}', style: const TextStyle(color: Color(0xFF71809B))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Row(children:[const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF71809B)), const SizedBox(width: 5), Text('Due ${b['due']}', style: const TextStyle(color: Color(0xFF71809B)))])),
                  TextButton.icon(
                    onPressed: () async {
                      final receipt = await showModalBottomSheet<Map<String,dynamic>>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => PackageUpgradeSheet(controller: widget.controller, bill: b),
                      );
                      if (receipt != null && context.mounted) {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => ProvisionalReceiptSheet(controller: widget.controller, receipt: receipt),
                        );
                      }
                    },
                    icon: const Icon(Icons.upgrade_rounded, size: 18),
                    label: const Text('Change Pkg'),
                  ),
                  const Icon(Icons.chevron_right, color: blue),
                ]),
              ]),
            );
          },
        ),
      )),
    ]);
  }
}

class CollectionSheet extends StatefulWidget {
  final AppController controller;
  final Map<String, dynamic> bill;
  const CollectionSheet({super.key, required this.controller, required this.bill});
  @override
  State<CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<CollectionSheet> {
  late final TextEditingController amount;
  final reference = TextEditingController();
  String method = 'Cash';
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final totalDue = int.tryParse('${widget.bill['total_due'] ?? 0}') ?? 0;
    final total = int.tryParse('${widget.bill['amount'] ?? 0}') ?? 0;
    final paid = int.tryParse('${widget.bill['paid'] ?? 0}') ?? 0;
    final due = totalDue > 0 ? totalDue : (total - paid);
    amount = TextEditingController(text: (due / 100).toStringAsFixed(2));
  }

  @override
  void dispose() { amount.dispose(); reference.dispose(); super.dispose(); }

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.controller.submitRequest({
        'kind': 'payment',
        'bill_id': widget.bill['id'],
        'amount': amount.text.trim(),
        'date': todayIso(),
        'method': method,
        'reference': reference.text.trim(),
      });
      final id = int.tryParse('${result['submitted_request_id'] ?? ''}');
      Map<String,dynamic>? receipt;
      if (id != null) {
        for (final item in widget.controller.collectionHistory) {
          if (int.tryParse('${item['id']}') == id) { receipt = item; break; }
        }
      }
      if (mounted) Navigator.pop(context, receipt);
    } on ApiException catch (e) { setState(() => error = e.message); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: const Color(0xFFD5DCE7), borderRadius: BorderRadius.circular(99))),
      Text('${widget.bill['name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
      const SizedBox(height: 4),
      Text('${widget.bill['village']} • Bill #${widget.bill['id']} • ${widget.bill['month']}', style: const TextStyle(color: Color(0xFF71809B))),
      const SizedBox(height: 20),
      Builder(builder: (_) { final current = (int.tryParse('${widget.bill['amount'] ?? 0}') ?? 0) - (int.tryParse('${widget.bill['paid'] ?? 0}') ?? 0); final previousBalance = int.tryParse('${widget.bill['previous_balance'] ?? 0}') ?? 0; final previousPending = int.tryParse('${widget.bill['previous_pending'] ?? 0}') ?? 0; final previousMonth = shortMonthLabel(widget.bill['previous_balance_month']); final totalDue = int.tryParse('${widget.bill['total_due'] ?? (current + previousBalance + previousPending)}') ?? (current + previousBalance + previousPending); return AppCard(color: const Color(0xFFF7F9FD), child: Column(children:[_InfoRow(icon:Icons.history_outlined,label:'Previous Balance',value:money(previousBalance)),if(previousBalance>0 && previousMonth.isNotEmpty)_InfoRow(icon:Icons.calendar_month_outlined,label:'Previous Balance Month',value:previousMonth),if(previousPending>0)_InfoRow(icon:Icons.history_toggle_off,label:'Previous Pending',value:money(previousPending)),_InfoRow(icon:Icons.receipt_long_outlined,label:'Current Bill',value:money(current)),_InfoRow(icon:Icons.account_balance_wallet_outlined,label:'Total Due',value:money(totalDue))])); }),
      const SizedBox(height: 12),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fieldDecoration('Amount received (PKR)', icon: Icons.payments_outlined)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: method, decoration: fieldDecoration('Payment method'), items: ['Cash','Bank transfer','JazzCash','Easypaisa'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => method = v ?? 'Cash')),
      const SizedBox(height: 12),
      TextField(controller: reference, decoration: fieldDecoration('Reference (optional)', icon: Icons.numbers_outlined)),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: red))),
      const SizedBox(height: 18),
      SizedBox(height: 52, child: FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Submitting…' : 'Submit for Approval'))),
    ])),
  );
}


class PackageUpgradeSheet extends StatefulWidget {
  final AppController controller;
  final Map<String, dynamic> bill;
  const PackageUpgradeSheet({super.key, required this.controller, required this.bill});
  @override
  State<PackageUpgradeSheet> createState() => _PackageUpgradeSheetState();
}

class _PackageUpgradeSheetState extends State<PackageUpgradeSheet> {
  int? packageId;
  late final TextEditingController newAmount;
  final notes = TextEditingController();
  final reference = TextEditingController();
  String method = 'Cash';
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final billAmount = int.tryParse('${widget.bill['amount'] ?? 0}') ?? 0;
    newAmount = TextEditingController(text: (billAmount / 100).toStringAsFixed(2));
  }

  @override
  void dispose() { newAmount.dispose(); notes.dispose(); reference.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (packageId == null) { setState(() => error = 'Select the new package.'); return; }
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.controller.submitRequest({
        'kind': 'package_upgrade',
        'bill_id': widget.bill['id'],
        'package_id': packageId,
        'new_amount': newAmount.text.trim(),
        'date': todayIso(),
        'method': method,
        'reference': reference.text.trim(),
        'notes': notes.text.trim(),
      });
      final id = int.tryParse('${result['submitted_request_id'] ?? ''}');
      Map<String,dynamic>? receipt;
      if (id != null) {
        for (final item in widget.controller.collectionHistory) {
          if (int.tryParse('${item['id']}') == id) { receipt = item; break; }
        }
      }
      if (mounted) {
        Navigator.pop(context, receipt);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package change receipt ready. Admin approval is pending for official posting.')));
      }
    } on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final packages = widget.controller.packages;
    final currentAmount = int.tryParse('${widget.bill['amount'] ?? 0}') ?? 0;
    final paid = int.tryParse('${widget.bill['paid'] ?? 0}') ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: const Color(0xFFD5DCE7), borderRadius: BorderRadius.circular(99))),
        const Text('Change Package Request', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 5),
        Text('${widget.bill['name']} • Bill #${widget.bill['id']} • ${widget.bill['month']}', style: const TextStyle(color: Color(0xFF71809B))),
        const SizedBox(height: 16),
        AppCard(color: const Color(0xFFF7F9FD), child: Column(children: [
          _InfoRow(icon: Icons.wifi_outlined, label: 'Current package', value: '${widget.bill['customer_package'] ?? widget.bill['package'] ?? '—'}'),
          _InfoRow(icon: Icons.receipt_long_outlined, label: 'Current bill', value: money(currentAmount)),
          if (paid > 0) _InfoRow(icon: Icons.payments_outlined, label: 'Already received', value: money(paid)),
        ])),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: packageId,
          decoration: fieldDecoration('New package', icon: Icons.speed_outlined),
          items: packages.map((p) {
            final id = int.tryParse('${p['id']}') ?? 0;
            final speed = '${p['speed'] ?? ''}'.trim();
            final name = '${p['name'] ?? ''}'.trim();
            final fee = int.tryParse('${p['fee'] ?? 0}') ?? 0;
            final label = speed.isNotEmpty ? '$speed • ${money(fee)}' : '$name • ${money(fee)}';
            return DropdownMenuItem<int>(value: id, child: Text(label));
          }).toList(),
          onChanged: (v) {
            setState(() => packageId = v);
            final selected = packages.where((p) => int.tryParse('${p['id']}') == v).toList();
            if (selected.isNotEmpty) {
              final fee = int.tryParse('${selected.first['fee'] ?? 0}') ?? 0;
              if (fee > 0) newAmount.text = (fee / 100).toStringAsFixed(2);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(controller: newAmount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fieldDecoration('Amount received / new bill (PKR)', icon: Icons.currency_rupee_rounded)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: method, decoration: fieldDecoration('Payment method'), items: ['Cash','Bank transfer','JazzCash','Easypaisa'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => method = v ?? 'Cash')),
        const SizedBox(height: 12),
        TextField(controller: reference, decoration: fieldDecoration('Reference (optional)', icon: Icons.numbers_outlined)),
        const SizedBox(height: 12),
        TextField(controller: notes, maxLines: 2, decoration: fieldDecoration('Notes (optional)', hint: 'Package change details', icon: Icons.notes_outlined)),
        const SizedBox(height: 8),
        const Text('Receipt abhi print ho sakti hai. Package, bill aur payment admin approval ke baad official calculation mein add honge.', style: TextStyle(fontSize: 12, color: Color(0xFF71809B))),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: red))),
        const SizedBox(height: 18),
        SizedBox(height: 52, child: FilledButton(onPressed: busy || packages.isEmpty ? null : submit, child: Text(busy ? 'Submitting…' : 'Send Package Change Request'))),
      ])),
    );
  }
}


class CollectionHistoryPage extends StatefulWidget {
  final AppController controller;
  const CollectionHistoryPage({super.key, required this.controller});
  @override State<CollectionHistoryPage> createState() => _CollectionHistoryPageState();
}

class _CollectionHistoryPageState extends State<CollectionHistoryPage> {
  String month = '';
  @override
  Widget build(BuildContext context) {
    final all = widget.controller.collectionHistory;
    final months = <String>{for (final r in all) '${(r['payload'] is Map ? r['payload']['month'] : '') ?? ''}'}.where((e)=>e.isNotEmpty).toList()..sort((a,b)=>b.compareTo(a));
    final list = all.where((r) => month.isEmpty || (r['payload'] is Map && '${r['payload']['month']}' == month)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Receipts')),
      body: RefreshIndicator(
        onRefresh: widget.controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            DropdownButtonFormField<String>(
              value: month,
              decoration: fieldDecoration('Month', icon: Icons.calendar_month_outlined),
              items: [const DropdownMenuItem(value:'',child:Text('All months')), ...months.map((m)=>DropdownMenuItem(value:m,child:Text(m)))],
              onChanged: (v)=>setState(()=>month=v??''),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty) const EmptyState(title:'No receipts', message:'No collection receipts match this month.', icon: Icons.receipt_long_outlined)
            else ...list.map((r) {
              final p = r['payload'] is Map ? Map<String,dynamic>.from(r['payload']) : <String,dynamic>{};
              final status='${r['status'] ?? 'Pending'}';
              final color=status=='Approved'?green:status=='Rejected'?red:orange;
              return Padding(
                padding: const EdgeInsets.only(bottom:10),
                child: AppCard(
                  child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[Expanded(child:Text('${r['receipt_no'] ?? ''} • ${r['customer_name'] ?? p['name'] ?? ''}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16,color:navy))),StatusPill(status,color:color)]),
                    const SizedBox(height:6),
                    Text('${r['village'] ?? ''} • ${p['month'] ?? ''} • ${r['created_at'] ?? ''}',style:const TextStyle(color:Color(0xFF71809B))),
                    const SizedBox(height:8),
                    Text('Collected ${money(p['amount'])} • ${p['method'] ?? ''}',style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),
                    const SizedBox(height:10),
                    SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>ProvisionalReceiptSheet(controller:widget.controller,receipt:r)),icon:const Icon(Icons.print_outlined),label:const Text('Print / Reprint 58mm Receipt'))),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ProvisionalReceiptSheet extends StatefulWidget {
  final AppController controller;
  final Map<String,dynamic> receipt;
  const ProvisionalReceiptSheet({super.key,required this.controller,required this.receipt});
  @override State<ProvisionalReceiptSheet> createState()=>_ProvisionalReceiptSheetState();
}
class _ProvisionalReceiptSheetState extends State<ProvisionalReceiptSheet> {
  bool busy=false; String? message;
  Future<void> printReceipt() async {
    setState(()=>busy=true);
    try {
      final printers=await ThermalPrinterService.pairedPrinters();
      if(!mounted)return;
      if(printers.isEmpty){throw ThermalPrinterException('No paired Bluetooth printer found. Pair ZJ-5205 in phone Bluetooth settings first.');}
      final selected=await showDialog<BluetoothInfo>(context:context,builder:(ctx)=>SimpleDialog(title:const Text('Select thermal printer'),children:printers.map((p)=>SimpleDialogOption(onPressed:()=>Navigator.pop(ctx,p),child:ListTile(leading:const Icon(Icons.print_outlined),title:Text(p.name.isEmpty?'Thermal printer':p.name),subtitle:Text(p.macAdress)))).toList()));
      if(selected==null)return;
      await ThermalPrinterService.printReceipt(printer:selected,receipt:widget.receipt,collector:widget.controller.name);
      if(mounted)setState(()=>message='Receipt sent to ${selected.name}.');
    } catch(e) { if(mounted)setState(()=>message=e.toString()); }
    finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context){final r=widget.receipt;final p=r['payload'] is Map?Map<String,dynamic>.from(r['payload']):<String,dynamic>{};final status='${r['status']??'Pending'}';return Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(context).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Container(width:44,height:5,margin:const EdgeInsets.only(bottom:18),decoration:BoxDecoration(color:const Color(0xFFD5DCE7),borderRadius:BorderRadius.circular(99))),
    Text(p['package_upgrade']==true?'Package Changed Receipt':'Provisional Collection Receipt',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:6),
    Text(AppConfig.companyPhone,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:6),
    Text('${r['receipt_no']??''} • $status',style:TextStyle(color:status=='Approved'?green:status=='Rejected'?red:orange,fontWeight:FontWeight.w800)),const SizedBox(height:16),
    AppCard(color:const Color(0xFFF7F9FD),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_InfoRow(icon:Icons.person_outline,label:'User',value:'${r['customer_name']??p['name']??''}'),_InfoRow(icon:Icons.calendar_month_outlined,label:'Bill month',value:'${p['month']??''}'),if(p['package_upgrade']==true)_InfoRow(icon:Icons.upgrade_rounded,label:'Package',value:'${p['new_package']??p['package_name']??''}'),_InfoRow(icon:Icons.history_outlined,label:'Previous Balance',value:money(r['previous_balance'] ?? p['previous_balance'] ?? 0)),if('${r['previous_balance_month'] ?? p['previous_balance_month'] ?? ''}'.isNotEmpty)_InfoRow(icon:Icons.calendar_month_outlined,label:'Previous Balance Month',value:shortMonthLabel(r['previous_balance_month'] ?? p['previous_balance_month'])),if((int.tryParse('${r['previous_pending'] ?? p['previous_pending'] ?? 0}') ?? 0)>0)_InfoRow(icon:Icons.history_toggle_off,label:'Previous Pending',value:money(r['previous_pending'] ?? p['previous_pending'] ?? 0)),_InfoRow(icon:Icons.receipt_long_outlined,label:'Current Bill',value:money(r['current_bill'] ?? p['current_bill'] ?? 0)),_InfoRow(icon:Icons.account_balance_wallet_outlined,label:'Total Due',value:money(r['total_due_before'] ?? p['total_due_before'])),_InfoRow(icon:Icons.payments_outlined,label:'Amount Paid',value:money(p['amount'])),_InfoRow(icon:Icons.account_balance_wallet_outlined,label:'Remaining',value:money(r['provisional_balance'])),_InfoRow(icon:Icons.payment_outlined,label:'Method',value:'${p['method']??''}') ])),
    const SizedBox(height:12),
    if(status=='Pending' && p['package_upgrade']!=true) const Text('Pending Admin Approval: this receipt confirms field collection only. Official office posting happens after admin approval.',style:TextStyle(color:orange,fontWeight:FontWeight.w700)),
    if(message!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(message!,style:const TextStyle(color:navy))),const SizedBox(height:16),
    SizedBox(height:54,child:FilledButton.icon(onPressed:busy?null:printReceipt,icon:const Icon(Icons.print_rounded),label:Text(busy?'Connecting…':'Print on 58mm Bluetooth Printer'))),
  ])) );}
}

class ConnectionPage extends StatefulWidget {
  final AppController controller;
  const ConnectionPage({super.key, required this.controller});
  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final cnic = TextEditingController();
  final package = TextEditingController();
  final fee = TextEditingController();
  final address = TextEditingController();
  final notes = TextEditingController();
  dynamic villageId;
  bool busy = false;
  String? error;

  @override
  void initState() { super.initState(); if (widget.controller.villages.isNotEmpty) villageId = widget.controller.villages.first['id']; }
  @override
  void dispose() { for (final c in [name,phone,cnic,package,fee,address,notes]) c.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (villageId == null) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.controller.submitRequest({
        'kind':'connection','name':name.text.trim(),'phone':phone.text.trim(),'cnic':cnic.text.trim(),
        'village_id':villageId,'package':package.text.trim(),'fee':fee.text.trim(),'joined':todayIso(),
        'address':address.text.trim(),'notes':notes.text.trim(),
      });
      for (final c in [name,phone,cnic,package,fee,address,notes]) c.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New connection submitted for approval.')));
    } on ApiException catch (e) { setState(() => error = e.message); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final villages = widget.controller.villages;
    return ListView(padding: EdgeInsets.zero, children: [
      PageHeader(title: 'New Connection', subtitle: 'Submit a customer connection for admin approval.', controller: widget.controller),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: name, decoration: fieldDecoration('Customer name', icon: Icons.person_outline)), const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: fieldDecoration('Phone', hint: '0300-1234567', icon: Icons.phone_outlined)), const SizedBox(height: 12),
        TextField(controller: cnic, keyboardType: TextInputType.number, decoration: fieldDecoration('CNIC', hint: '81101-1111111-1', icon: Icons.badge_outlined)), const SizedBox(height: 12),
        DropdownButtonFormField<dynamic>(value: villageId, decoration: fieldDecoration('Village', icon: Icons.location_city_outlined), items: villages.map((v) => DropdownMenuItem(value: v['id'], child: Text('${v['name']}'))).toList(), onChanged: (v) => setState(() => villageId = v)), const SizedBox(height: 12),
        TextField(controller: package, decoration: fieldDecoration('Package', hint: 'e.g. 10 Mbps', icon: Icons.wifi_rounded)), const SizedBox(height: 12),
        TextField(controller: fee, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fieldDecoration('Monthly fee (PKR)', icon: Icons.payments_outlined)), const SizedBox(height: 12),
        TextField(controller: address, maxLines: 2, decoration: fieldDecoration('Address', icon: Icons.home_outlined)), const SizedBox(height: 12),
        TextField(controller: notes, maxLines: 3, decoration: fieldDecoration('Notes (optional)', icon: Icons.notes_outlined)),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: red))),
        const SizedBox(height: 18),
        SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : submit, icon: const Icon(Icons.send_rounded), label: Text(busy ? 'Submitting…' : 'Submit Connection'))),
      ]))),
    ]);
  }
}

class ComplaintsPage extends StatelessWidget {
  final AppController controller;
  const ComplaintsPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final items = controller.complaints;
    return Column(children: [
      PageHeader(title: 'Complaints', subtitle: 'Report completed fixes for admin review.', controller: controller, actions: [IconButton(onPressed: controller.refresh, icon: const Icon(Icons.refresh))]),
      Expanded(child: items.isEmpty ? const EmptyState(title: 'No assigned complaints', message: 'There are no open complaints assigned to you right now.', icon: Icons.task_alt_rounded) : RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90), itemCount: items.length, separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (_, i) { final c = items[i]; return AppCard(onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ComplaintSheet(controller: controller, complaint: c)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('#${c['id']} • ${c['subject']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: navy))), Chip(label: Text('${c['priority']}'))]),
            Text('${c['name']} • ${c['village']}', style: const TextStyle(color: Color(0xFF71809B))), const SizedBox(height: 8), Text('${c['description']}', maxLines: 3, overflow: TextOverflow.ellipsis),
          ])); },
        ),
      )),
    ]);
  }
}

class ComplaintSheet extends StatefulWidget {
  final AppController controller;
  final Map<String,dynamic> complaint;
  const ComplaintSheet({super.key, required this.controller, required this.complaint});
  @override
  State<ComplaintSheet> createState() => _ComplaintSheetState();
}
class _ComplaintSheetState extends State<ComplaintSheet> {
  final resolution = TextEditingController(); bool busy=false; String? error;
  @override void dispose(){resolution.dispose();super.dispose();}
  Future<void> submit() async { setState(() {busy=true;error=null;}); try { await widget.controller.submitRequest({'kind':'complaint','complaint_id':widget.complaint['id'],'resolution':resolution.text.trim()}); if(mounted) Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fix report submitted for review.'))); } on ApiException catch(e){setState(()=>error=e.message);} finally {if(mounted)setState(()=>busy=false);} }
  @override Widget build(BuildContext context)=>Padding(padding: EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(context).viewInsets.bottom+18), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
    Container(width:44,height:5,margin:const EdgeInsets.only(bottom:18),decoration:BoxDecoration(color:const Color(0xFFD5DCE7),borderRadius:BorderRadius.circular(99))),
    Text('${widget.complaint['subject']}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:6),Text('${widget.complaint['name']} • ${widget.complaint['village']}',style:const TextStyle(color:Color(0xFF71809B))),const SizedBox(height:12),Text('${widget.complaint['description']}'),const SizedBox(height:18),
    TextField(controller:resolution,maxLines:5,decoration:fieldDecoration('Work completed / fix report',icon:Icons.handyman_outlined)),if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:red))),const SizedBox(height:18),SizedBox(height:52,child:FilledButton(onPressed:busy?null:submit,child:Text(busy?'Submitting…':'Report Fixed')))
  ])));
}

class ProfilePage extends StatefulWidget {
  final AppController controller;
  const ProfilePage({super.key, required this.controller});
  @override State<ProfilePage> createState()=>_ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  final picker = ImagePicker();
  bool photoBusy = false;
  String statusFilter = 'All';

  Future<void> choosePhoto() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    setState(() => photoBusy = true);
    try {
      await widget.controller.updateProfilePhoto(file);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.profile;
    final permissions = <String>[
      if ('${p['can_collect']}' == '1') 'Collections',
      if ('${p['can_connect']}' == '1') 'Connections',
      if ('${p['can_complaints']}' == '1') 'Complaints',
    ];
    final requests = c.requests
        .where((r) => statusFilter == 'All' || '${r['status']}' == statusFilter)
        .toList();

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          AppCard(
            child: Column(children: [
              _Avatar(controller: c, size: 86),
              const SizedBox(height: 12),
              Text(c.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
              Text('${p['role'] ?? 'Staff'} • ${p['phone'] ?? ''}', style: const TextStyle(color: Color(0xFF71809B))),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: photoBusy ? null : choosePhoto,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: Text(photoBusy ? 'Updating…' : 'Change Photo'),
                  ),
                  if (c.photoUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => c.removeProfilePhoto(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.badge_outlined, label: 'Staff ID', value: '${p['app_username'] ?? '—'}'),
              _InfoRow(icon: Icons.location_city_outlined, label: 'Assigned villages', value: '${c.villages.length}'),
              _InfoRow(icon: Icons.security_outlined, label: 'Permissions', value: permissions.isEmpty ? 'Profile only' : permissions.join(' • ')),
            ]),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children:[const Expanded(child:Text('Assigned Assets',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:navy))),Chip(label:Text('${c.assignedAssets.length}'))]),
              const SizedBox(height:8),
              if(c.assignedAssets.isEmpty) const Text('No equipment is assigned to your staff account.',style:TextStyle(color:Color(0xFF71809B)))
              else ...c.assignedAssets.map((a)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFF5F8FE),borderRadius:BorderRadius.circular(14)),child:Row(children:[const Icon(Icons.router_outlined,color:blue),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${a['name']}',style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),Text('${a['asset_code']} • ${a['model'] ?? ''}',style:const TextStyle(fontSize:12,color:Color(0xFF71809B)))]))])))),
            ]),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children:[const Expanded(child:Text('Daily Expenses',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:navy))),FilledButton.icon(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>ExpenseSubmitSheet(controller:c)),icon:const Icon(Icons.add,size:18),label:const Text('Add'))]),
              const SizedBox(height:8),
              const Text('Only you can see your submitted expenses here. Admin can review the complete expense register.',style:TextStyle(color:Color(0xFF71809B),fontSize:12)),
              const SizedBox(height:10),
              if(c.expenseRequests.isEmpty) const Text('No expense requests submitted yet.',style:TextStyle(color:Color(0xFF71809B)))
              else ...c.expenseRequests.take(8).map((e)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFF8FAFD),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFE5EBF5))),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${e['category']} • ${money(e['amount'])}',style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),Text('${e['date']} • ${e['description']}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:Color(0xFF71809B)))])),Chip(label:Text('${e['status']}'))])))),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Text('Pending / Rejected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy))),
            DropdownButton<String>(
              value: statusFilter,
              items: ['All', 'Pending', 'Rejected'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => statusFilter = v ?? 'All'),
            ),
          ]),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            const AppCard(child: Text('No pending or rejected requests.', style: TextStyle(color: Color(0xFF71809B))))
          else
            ...requests.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('#${r['id']} • ${r['kind']=='package_upgrade'?'Package change':r['kind']}', style: const TextStyle(fontWeight: FontWeight.w900, color: navy))),
                        Chip(label: Text('${r['status']}')),
                      ]),
                      Text('${r['created_at']}', style: const TextStyle(color: Color(0xFF71809B))),
                      if ('${r['review_note'] ?? ''}'.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text('Admin note: ${r['review_note']}')),
                    ]),
                  ),
                )),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(onPressed: () => c.logout(), icon: const Icon(Icons.logout), label: const Text('Sign Out')),
          ),
        ],
      ),
    );
  }
}


class ExpenseSubmitSheet extends StatefulWidget {
  final AppController controller;
  const ExpenseSubmitSheet({super.key,required this.controller});
  @override State<ExpenseSubmitSheet> createState()=>_ExpenseSubmitSheetState();
}
class _ExpenseSubmitSheetState extends State<ExpenseSubmitSheet>{
  final category=TextEditingController();final description=TextEditingController();final amount=TextEditingController();final reference=TextEditingController();bool busy=false;String? error;
  @override void dispose(){category.dispose();description.dispose();amount.dispose();reference.dispose();super.dispose();}
  Future<void> submit() async {setState(()=>busy=true);try{await widget.controller.submitExpense({'date':todayIso(),'category':category.text.trim(),'description':description.text.trim(),'amount':amount.text.trim(),'reference':reference.text.trim()});if(mounted)Navigator.pop(context);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Expense submitted for admin review.')));}on ApiException catch(e){setState(()=>error=e.message);}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(context).viewInsets.bottom+18),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Container(width:44,height:5,margin:const EdgeInsets.only(bottom:18),decoration:BoxDecoration(color:const Color(0xFFD5DCE7),borderRadius:BorderRadius.circular(99))),const Text('Daily Expense',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:14),TextField(controller:category,decoration:fieldDecoration('Category',hint:'Fuel, repair, travel…',icon:Icons.category_outlined)),const SizedBox(height:12),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:fieldDecoration('Amount (PKR)',icon:Icons.payments_outlined)),const SizedBox(height:12),TextField(controller:description,maxLines:3,decoration:fieldDecoration('Description',icon:Icons.notes_outlined)),const SizedBox(height:12),TextField(controller:reference,decoration:fieldDecoration('Reference (optional)',icon:Icons.numbers_outlined)),if(error!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(error!,style:const TextStyle(color:red))),const SizedBox(height:16),SizedBox(height:52,child:FilledButton(onPressed:busy?null:submit,child:Text(busy?'Submitting…':'Submit Expense')))])));
}

class _InfoRow extends StatelessWidget {final IconData icon;final String label,value;const _InfoRow({required this.icon,required this.label,required this.value});@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:blue,size:21),const SizedBox(width:11),SizedBox(width:105,child:Text(label,style:const TextStyle(color:Color(0xFF71809B)))),Expanded(child:Text(value,style:const TextStyle(fontWeight:FontWeight.w700,color:navy))) ]));}

class _Avatar extends StatelessWidget {final AppController controller;final double size;const _Avatar({required this.controller,required this.size});@override Widget build(BuildContext context){final url=controller.photoUrl;return Container(width:size,height:size,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(gradient:const LinearGradient(colors:[blue,purple]),borderRadius:BorderRadius.circular(size*.3),boxShadow:const[BoxShadow(color:Color(0x223E5CF6),blurRadius:14,offset:Offset(0,6))]),child:url.isNotEmpty?Image.network(url,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Center(child:Text(controller.name.isEmpty?'K':controller.name[0].toUpperCase(),style:TextStyle(color:Colors.white,fontSize:size*.4,fontWeight:FontWeight.w900)))):Center(child:Text(controller.name.isEmpty?'K':controller.name[0].toUpperCase(),style:TextStyle(color:Colors.white,fontSize:size*.4,fontWeight:FontWeight.w900))));}}
