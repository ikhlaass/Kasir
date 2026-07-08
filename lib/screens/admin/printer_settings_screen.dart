import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../services/database_helper.dart';
import '../../services/printer_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  final DatabaseHelper _db = DatabaseHelper();

  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _savedMac = '';
  String _savedName = '';

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final mac = await _db.getSetting('printer_mac');
    final name = await _db.getSetting('printer_name');
    final connected = await _printerService.isConnected;

    if (mounted) {
      setState(() {
        _savedMac = mac;
        _savedName = name;
        _isConnected = connected;
      });
    }
  }

  Future<void> _scanDevices() async {
    if (!_printerService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pencarian Bluetooth hanya didukung di perangkat Android/iOS.',
          ),
        ),
      );
      return;
    }

    // Request permissions for Android 12+
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect]?.isDenied == true ||
        statuses[Permission.bluetoothScan]?.isDenied == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin Bluetooth diperlukan untuk mencari printer.'),
          ),
        );
      }
      return;
    }

    setState(() => _isScanning = true);
    final devices = await _printerService.getPairedDevices();

    if (mounted) {
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothInfo device) async {
    setState(() => _isScanning = true); // use as loading indicator

    final success = await _printerService.connect(device.macAdress);

    if (success) {
      await _db.setSetting('printer_mac', device.macAdress);
      await _db.setSetting('printer_name', device.name);
      await _loadSavedPrinter();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil terhubung ke ${device.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal terhubung ke printer.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isScanning = false);
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    await _db.setSetting('printer_mac', '');
    await _db.setSetting('printer_name', '');
    await _loadSavedPrinter();
  }

  Future<void> _testPrint() async {
    if (!_isConnected) return;
    try {
      // Print dummy text directly
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.text(
        'TEST PRINTER BERHASIL!',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.emptyLines(2);
      await PrintBluetoothThermal.writeBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test print dikirim.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print gagal: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (!_printerService.isSupported) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Pengaturan Printer',
            style: AppFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.print_disabled,
                size: 64,
                color: AppColors.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Bluetooth Thermal Printer\nhanya didukung di Android/iOS.',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan Printer',
          style: AppFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Status Printer Saat Ini
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isConnected
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.print_rounded,
                  color: _isConnected ? AppColors.success : AppColors.textLight,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'Terhubung' : 'Tidak Terhubung',
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? AppColors.success
                              : AppColors.textMedium,
                        ),
                      ),
                      if (_savedName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$_savedName ($_savedMac)',
                          style: AppFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isConnected)
                  ElevatedButton(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text('Putus', style: AppFonts.poppins(fontSize: 12)),
                  ),
              ],
            ),
          ),

          if (_isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testPrint,
                  icon: Icon(Icons.receipt_long),
                  label: Text('Test Print', style: AppFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Perangkat Bluetooth Tersimpan/Paired',
                style: AppFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isScanning
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada perangkat ditemukan.\nPastikan bluetooth menyala dan printer sudah di-pairing.',
                      textAlign: TextAlign.center,
                      style: AppFonts.poppins(color: AppColors.textMedium),
                    ),
                  )
                : ListView.separated(
                    itemCount: _devices.length,
                    separatorBuilder: (c, i) => Divider(),
                    itemBuilder: (ctx, i) {
                      final dev = _devices[i];
                      final isThisConnected =
                          _isConnected && _savedMac == dev.macAdress;
                      return ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text(
                          dev.name,
                          style: AppFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          dev.macAdress,
                          style: AppFonts.poppins(fontSize: 11),
                        ),
                        trailing: isThisConnected
                            ? Icon(Icons.check_circle, color: AppColors.success)
                            : TextButton(
                                onPressed: () => _connectToDevice(dev),
                                child: Text('Konek', style: AppFonts.poppins()),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _printerService.isSupported
          ? FloatingActionButton.extended(
              heroTag: 'scan_bt',
              onPressed: _scanDevices,
              icon: Icon(Icons.search),
              label: Text('Cari Ulang', style: AppFonts.poppins()),
            )
          : null,
    );
  }
}
