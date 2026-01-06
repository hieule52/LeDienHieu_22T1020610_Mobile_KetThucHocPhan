import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/address_controller.dart';
import '../models/address_model.dart';
import 'add_edit_address_page.dart';

class AddressListPage extends StatelessWidget {
  final bool selectMode;
  const AddressListPage({super.key, this.selectMode = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddressController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Địa chỉ nhận hàng',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.addresses.length,
              itemBuilder: (context, index) {
                final address = controller.addresses[index];
                return _buildAddressItem(context, address, controller);
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditAddressPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B14F),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Thêm địa chỉ mới',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressItem(
    BuildContext context,
    AddressModel address,
    AddressController controller,
  ) {
    return InkWell(
      onTap: selectMode
          ? () {
              Navigator.pop(context, address);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: address.isDefault
                ? const Color(0xFF00B14F)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        address.phone,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (selectMode) returnRadio(context, address),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditAddressPage(address: address),
                      ),
                    );
                  },
                  child: const Text(
                    'Sửa',
                    style: TextStyle(color: Color(0xFF00B14F)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(address.specificAddress),
            Text('${address.ward}, ${address.province}'),
            const SizedBox(height: 8),
            if (address.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00B14F)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Mặc định',
                  style: TextStyle(color: Color(0xFF00B14F), fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget returnRadio(BuildContext context, AddressModel address) {
    return const SizedBox.shrink(); // Simplify for now, selection handled by tap if needed
  }
}
