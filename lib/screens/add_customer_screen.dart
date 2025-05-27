import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/policy.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/database_helper.dart';
import '../utils/notification_helper.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:http/http.dart' as http; // Uncomment and add http package if using http
import 'dart:convert'; // Import dart:convert for JSON parsing

class AddCustomerScreen extends StatefulWidget {
  final Policy? policy; // Optional policy for editing
  const AddCustomerScreen({super.key, this.policy});

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _policyType; // Main policy type (Auto, Health)
  String? _autoPolicySubType; // Sub-type for Auto Policy (Third Party, Full, OD, Only OD, other)
  String? _policyCompany; // Insurance company
  DateTime? _policyStartDate; // Policy start date
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _coverageAmountController = TextEditingController();
  DateTime? _premiumDueDate;
  bool _isLoading = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final List<String> _autoPolicySubTypes = [
    'Third Party',
    'Full',
    'OD',
    'Only OD',
    'other',
  ];

  final List<String> _insuranceCompanies = [
    'Navi General Insurance Ltd.',
    'Reliance General Insurance Co. Ltd.',
    'Acko General Insurance Ltd.',
    'Bajaj Allianz General Insurance Co. Ltd.',
    'Bharti AXA General Insurance Co. Ltd.',
    'Cholamandalam MS General Insurance Co. Ltd.',
    'Future Generali India Insurance Co. Ltd.',
    'Go Digit General Insurance Ltd.',
    'HDFC ERGO General Insurance Co. Ltd.',
    'ICICI Lombard General Insurance Co. Ltd.',
    'IFFCO Tokio General Insurance Co. Ltd.',
    'Kotak Mahindra General Insurance Co. Ltd.',
    'Liberty General Insurance Ltd.',
    'Magma HDI General Insurance Co. Ltd.',
    'Raheja QBE General Insurance Co. Ltd.',
    'Royal Sundaram General Insurance Co. Ltd.',
    'SBI General Insurance Co. Ltd.',
    'Shriram General Insurance Co. Ltd.',
    'Tata AIG General Insurance Co. Ltd.',
    'The New India Assurance Co. Ltd.',
    'The Oriental Insurance Co. Ltd.',
    'United India Insurance Co. Ltd.',
    'Universal Sompo General Insurance Co. Ltd.',
    'Zuno General Insurance Ltd.',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      _policyType = widget.policy!.policyType;
      _autoPolicySubType = widget.policy!.autoPolicySubType;
      _policyCompany = widget.policy!.policyCompany;
      _policyStartDate = widget.policy!.policyStartDate != null
          ? DateTime.parse(widget.policy!.policyStartDate!)
          : null;
      _vehicleNumberController.text = widget.policy!.vehicleNumber ?? '';
      _customerNameController.text = widget.policy!.customerName;
      _contactNumberController.text = widget.policy!.contactNumber;
      _coverageAmountController.text = widget.policy!.coverageAmount.toString();
      _premiumDueDate = DateTime.parse(widget.policy!.premiumDueDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _premiumDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _premiumDueDate) {
      setState(() {
        _premiumDueDate = picked;
      });
    }
  }

  Future<void> _selectPolicyStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _policyStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _policyStartDate) {
      setState(() {
        _policyStartDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
      try {
        final policyToSave = Policy(
          id: widget.policy?.id, // Use existing ID if editing
          policyType: _policyType!,
          autoPolicySubType: _policyType == 'Auto Policy' ? _autoPolicySubType : null,
          policyCompany: _policyType == 'Auto Policy' ? _policyCompany : null,
          policyStartDate: _policyType == 'Auto Policy' && _policyStartDate != null
              ? _policyStartDate!.toIso8601String().split('T')[0]
              : null,
          vehicleNumber: _policyType == 'Auto Policy' ? _vehicleNumberController.text : null,
          customerName: _customerNameController.text,
          contactNumber: _contactNumberController.text,
          coverageAmount: double.parse(_coverageAmountController.text),
          premiumDueDate: _premiumDueDate!.toIso8601String().split('T')[0],
        );

        if (widget.policy == null) {
          // Add new policy
          int id = await _dbHelper.insertPolicy(policyToSave);
          if (id > 0) {
            policyToSave.id = id;
            if (policyToSave.id != null) {
              await NotificationHelper.schedulePolicyReminder(policyToSave);
            }
            Fluttertoast.showToast(msg: 'Policy added successfully!');
          }
        } else {
          // Update existing policy
          await _dbHelper.updatePolicy(policyToSave);
          // Re-schedule notification for updated policy
          if (policyToSave.id != null) {
            await NotificationHelper.schedulePolicyReminder(policyToSave);
          }
          Fluttertoast.showToast(msg: 'Policy updated successfully!');
        }

        // Clear form only if adding a new policy
        if (widget.policy == null) {
          _policyType = null;
          _autoPolicySubType = null;
          _policyCompany = null;
          _policyStartDate = null;
          _vehicleNumberController.clear();
          _customerNameController.clear();
          _contactNumberController.clear();
          _coverageAmountController.clear();
          _premiumDueDate = null;
          setState(() {});
        }

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: widget.policy == null ? 'Failed to add policy. Please try again.' : 'Failed to update policy. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to handle document analysis
  Future<void> _analyzeDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Only allow PDFs for now
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        setState(() {
          _isLoading = true; // Show loading indicator
        });

        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('http://127.0.0.1:5000/analyze-policy'), // Your Flask backend URL
          );
          request.files.add(await http.MultipartFile.fromPath('file', filePath));

          var response = await request.send();
          final responseBody = await response.stream.bytesToString();

          if (response.statusCode == 200) {
            final extractedData = json.decode(responseBody);

            // Populate form with extracted data
            setState(() {
              _policyType = extractedData['policy_type'];
              _autoPolicySubType = extractedData['auto_policy_sub_type']; // Assuming backend returns this
              _policyCompany = extractedData['insurer_name'];

              // Parse date strings
              if (extractedData['policy_start_date'] != null && extractedData['policy_start_date'].isNotEmpty) {
                _policyStartDate = DateTime.tryParse(extractedData['policy_start_date']);
              } else {
                _policyStartDate = null;
              }
              if (extractedData['policy_end_date'] != null && extractedData['policy_end_date'].isNotEmpty) {
                _premiumDueDate = DateTime.tryParse(extractedData['policy_end_date']); // Mapping end date to premium due date
              } else {
                _premiumDueDate = null;
              }

              _vehicleNumberController.text = extractedData['vehicle_number'] ?? '';
              _customerNameController.text = extractedData['policyholder_name'] ?? '';
              _contactNumberController.text = extractedData['contact_number'] ?? ''; // Assuming backend extracts this
              _coverageAmountController.text = extractedData['premium_amount']?.toString() ?? '';
            });

            Fluttertoast.showToast(msg: 'Document analyzed. Please review the details.');
          } else {
            // Handle API errors
            final errorData = json.decode(responseBody);
            Fluttertoast.showToast(msg: 'Failed to analyze document: ${errorData['error'] ?? 'Unknown error'}');
          }

        } catch (e) {
          Fluttertoast.showToast(msg: 'Error analyzing document: ${e.toString()}');
        } finally {
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _customerNameController.dispose();
    _contactNumberController.dispose();
    _coverageAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/123.jpg',
              height: 40.0, // Adjust height as needed
            ),
            const SizedBox(width: 10), // Spacing between logo and text
            Text(widget.policy == null ? 'Add New Policy' : 'Edit Policy'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Add the Analyze Document Button here
               ElevatedButton(
                onPressed: _isLoading ? null : _analyzeDocument,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Analyze Policy Document'),
              ),
              const SizedBox(height: 20),

              const Text(
                'Or manually enter policy details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
               const SizedBox(height: 20),


              const Text(
                'What type of policy is this?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              FormField<String>(
                validator: (value) {
                  if (_policyType == null) {
                    return 'Please select a policy type.';
                  }
                  return null;
                },
                builder: (FormFieldState<String> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RadioListTile<String>(
                        title: const Text('Auto Policy'),
                        value: 'Auto Policy',
                        groupValue: _policyType,
                        onChanged: _isLoading ? null : (value) {
                          setState(() {
                            _policyType = value;
                            state.didChange(value); // Notify FormField of change
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Health Insurance Policy'),
                        value: 'Health Insurance Policy',
                        groupValue: _policyType,
                        onChanged: _isLoading ? null : (value) {
                          setState(() {
                            _policyType = value;
                            state.didChange(value); // Notify FormField of change
                          });
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              if (_policyType != null) ...[
                if (_policyType == 'Auto Policy') ...[
                  // Policy Start Date
                  FormField<DateTime>(
                    validator: (value) {
                      if (_policyStartDate == null) {
                        return 'Please select a policy start date.';
                      }
                      return null;
                    },
                    builder: (FormFieldState<DateTime> state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              _policyStartDate == null
                                  ? 'Select Policy Start Date'
                                  : 'Policy Start Date: ${DateFormat('yyyy-MM-dd').format(_policyStartDate!)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _isLoading ? null : () async {
                              await _selectPolicyStartDate(context);
                              state.didChange(_policyStartDate); // Notify FormField of change
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                state.errorText!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Auto Policy Sub Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _autoPolicySubType,
                    decoration: const InputDecoration(
                      labelText: 'Policy Type',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select Policy Type'),
                    onChanged: _isLoading ? null : (String? newValue) {
                      setState(() {
                        _autoPolicySubType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a policy type.';
                      }
                      return null;
                    },
                    items: _autoPolicySubTypes.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Policy Company Dropdown
                  DropdownButtonFormField<String>(
                    value: _policyCompany,
                    decoration: const InputDecoration(
                      labelText: 'Policy Company',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select Policy Company'),
                    onChanged: _isLoading ? null : (String? newValue) {
                      setState(() {
                        _policyCompany = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a policy company.';
                      }
                      return null;
                    },
                    items: _insuranceCompanies.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number (e.g., PB01A0001)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle number';
                      }
                      // Basic regex for Indian vehicle numbers (example: PB62B7771)
                      // This regex is a simplified example and might need to be more robust
                      // if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$').hasMatch(value)) {
                      //   return 'Enter a valid Indian vehicle number format';
                      // }
                      return null;
                    },
                     readOnly: _isLoading, // Disable input when loading
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                   readOnly: _isLoading, // Disable input when loading
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _contactNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number (e.g., 9477770000)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    return null;
                  },
                   readOnly: _isLoading, // Disable input when loading
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _coverageAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Coverage Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter coverage amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                   readOnly: _isLoading, // Disable input when loading
                ),
                const SizedBox(height: 10),
                FormField<DateTime>(
                  validator: (value) {
                    if (_premiumDueDate == null) {
                      return 'Please select a premium due date.';
                    }
                    return null;
                  },
                  builder: (FormFieldState<DateTime> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            _premiumDueDate == null
                                ? 'Select Premium Due Date'
                                : 'Premium Due Date: ${DateFormat('yyyy-MM-dd').format(_premiumDueDate!)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _isLoading ? null : () async {
                            await _selectDate(context);
                            state.didChange(_premiumDueDate); // Notify FormField of change
                          },
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
