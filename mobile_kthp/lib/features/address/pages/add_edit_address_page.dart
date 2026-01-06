import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/address_controller.dart';
import '../models/address_model.dart';

class AddEditAddressPage extends StatefulWidget {
  final AddressModel? address;
  const AddEditAddressPage({super.key, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _provinceCtrl;

  late TextEditingController _wardCtrl;
  late TextEditingController _specificCtrl;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _provinceCtrl = TextEditingController(text: a?.province ?? '');
    _wardCtrl = TextEditingController(text: a?.ward ?? '');
    _specificCtrl = TextEditingController(text: a?.specificAddress ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Liên hệ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTextField(_nameCtrl, 'Họ và tên'),
            const SizedBox(height: 12),
            _buildTextField(
              _phoneCtrl,
              'Số điện thoại',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),
            const Text(
              'Địa chỉ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            _buildTextField(_provinceCtrl, 'Tỉnh/Thành phố'),
            const SizedBox(height: 12),
            _buildTextField(_wardCtrl, 'Phường/Xã'),
            const SizedBox(height: 12),
            _buildTextField(_specificCtrl, 'Tên đường, tòa nhà, số nhà'),

            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Đặt làm địa chỉ mặc định'),
              value: _isDefault,
              activeColor: const Color(0xFF00B14F),
              onChanged: (val) => setState(() => _isDefault = val),
            ),

            if (isEdit) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  context.read<AddressController>().deleteAddress(
                    widget.address!.id,
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Xóa địa chỉ'),
              ),
            ],

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B14F),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'HOÀN THÀNH',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (val) =>
          val == null || val.isEmpty ? 'Vui lòng nhập $hint' : null,
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newAddr = AddressModel(
        id: widget.address?.id ?? _generateId(),
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        province: _provinceCtrl.text,
        ward: _wardCtrl.text,
        specificAddress: _specificCtrl.text,
        isDefault: _isDefault,
      );

      final ctrl = context.read<AddressController>();
      if (widget.address != null) {
        ctrl.updateAddress(newAddr);
      } else {
        ctrl.addAddress(newAddr);
      }

      Navigator.pop(context);
    }
  }
}
