import 'package:flutter/material.dart';
import '../../Data Models/address.dart';

class AddressForm extends StatefulWidget {
  final Address? address;
  const AddressForm({Key? key, this.address}) : super(key: key);

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late final TextEditingController _country;
  late final TextEditingController _phone;
  String _addressType = 'Shipping';

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _fullName = TextEditingController(text: a?.fullName ?? '');
    _email = TextEditingController(text: a?.email ?? '');
    _address1 = TextEditingController(text: a?.addressLine1 ?? '');
    _address2 = TextEditingController(text: a?.addressLine2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _country = TextEditingController(text: a?.country ?? '');
    _phone = TextEditingController(text: a?.phoneNumber ?? '');
    _addressType = a?.addressType ?? 'Shipping';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      id: widget.address?.id,
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      addressType: _addressType,
      addressLine1: _address1.text.trim(),
      addressLine2: _address2.text.trim().isEmpty ? null : _address2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postal.text.trim(),
      country: _country.text.trim(),
      phoneNumber: _phone.text.trim(),
    );

    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          ListTile(
            title: Text(
              isEditing ? 'Edit Address' : 'Add Address',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextFormField(_fullName, 'Full name', validator: _requiredValidator),
                _buildTextFormField(_email, 'Email', keyboardType: TextInputType.emailAddress, validator: _emailValidator),

                DropdownButtonFormField<String>(
                  value: _addressType,
                  items: const [
                    DropdownMenuItem(value: 'Shipping', child: Text('Shipping')),
                    DropdownMenuItem(value: 'Billing', child: Text('Billing')),
                  ],
                  onChanged: (v) => setState(() => _addressType = v ?? 'Shipping'),
                  decoration: const InputDecoration(labelText: 'Address Type'),
                ),

                _buildTextFormField(_address1, 'Address Line 1', validator: _requiredValidator),
                _buildTextFormField(_address2, 'Address Line 2'),
                _buildTextFormField(_city, 'City', validator: _requiredValidator),
                _buildTextFormField(_state, 'State', validator: _requiredValidator),
                _buildTextFormField(_postal, 'Postal Code', validator: _requiredValidator),
                _buildTextFormField(_country, 'Country', validator: _requiredValidator),
                _buildTextFormField(_phone, 'Phone Number', keyboardType: TextInputType.phone, validator: _requiredValidator),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'Save' : 'Add'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String labelText, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final re = RegExp(r'^\S+@\S+\.\S+$');
    if (!re.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }
}