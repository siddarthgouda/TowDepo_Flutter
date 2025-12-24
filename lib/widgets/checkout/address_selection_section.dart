import 'package:flutter/material.dart';
import '../../Data Models/address.dart';
import '../../services/address_service.dart';

class AddressSelectionSection extends StatelessWidget {
  final List<Address> addresses;
  final bool loadingAddresses;
  final String? addressError;
  final String? selectedAddressId;
  final Function(String?) onAddressSelected;
  final VoidCallback onAddAddress;
  final Function(Address) onEditAddress;
  final Function(List<Address>) onAddressesUpdated;

  const AddressSelectionSection({
    Key? key,
    required this.addresses,
    required this.loadingAddresses,
    required this.addressError,
    required this.selectedAddressId,
    required this.onAddressSelected,
    required this.onAddAddress,
    required this.onEditAddress,
    required this.onAddressesUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (loadingAddresses) _buildLoadingState(),
            if (addressError != null) _buildErrorState(context),
            if (!loadingAddresses && addressError == null) _buildAddressList(context),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Shipping Address',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // More compact button
        IconButton(
          onPressed: onAddAddress,
          icon: const Icon(Icons.add),
          tooltip: 'Add Address',
          style: IconButton.styleFrom(
            backgroundColor:Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.shade400,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Failed to load addresses',
          style: TextStyle(
            color: Colors.red.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          addressError ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAddAddress,
          icon: const Icon(Icons.add),
          label: const Text('Add Address'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressList(BuildContext context) {
    if (addresses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...addresses.map((address) {
          return _buildAddressTile(context, address);
        }).toList(),
        // Removed the bottom "Add New Address" button
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(
          Icons.location_off_outlined,
          color: Colors.grey.shade400,
          size: 48,
        ),
        const SizedBox(height: 8),
        const Text(
          'No addresses found',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAddAddress,
          icon: const Icon(Icons.add),
          label: const Text('Add Address'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTile(BuildContext context, Address address) {
    final isSelected = selectedAddressId == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button
            Radio<String?>(
              value: address.id,
              groupValue: selectedAddressId,
              onChanged: onAddressSelected,
            ),
            const SizedBox(width: 8),

            // Address details - takes available space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.addressLine1}${address.addressLine2 != null ? ', ${address.addressLine2}' : ''}',
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.city}, ${address.state} ${address.postalCode}',
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.phoneNumber,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () => onEditAddress(address),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // Delete Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  onPressed: () => _showDeleteDialog(context, address),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showDeleteDialog(BuildContext context, Address address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Address'),
          content: Text(
            'Are you sure you want to delete the address for ${address.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _deleteAddress(context, address),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAddress(BuildContext context, Address address) async {
    try {
      if (address.id != null) {
        await AddressService.deleteAddress(address.id!);

        // Remove the address from the list
        final updatedAddresses = List<Address>.from(addresses)
          ..removeWhere((a) => a.id == address.id);

        // Update the selected address if it was the deleted one
        String? newSelectedAddressId = selectedAddressId;
        if (selectedAddressId == address.id) {
          newSelectedAddressId = updatedAddresses.isNotEmpty ? updatedAddresses.first.id : null;
        }

        // Call the callback to update parent state
        onAddressesUpdated(updatedAddresses);

        // Close the dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address for ${address.fullName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Update selected address in parent
        if (newSelectedAddressId != selectedAddressId) {
          onAddressSelected(newSelectedAddressId);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}