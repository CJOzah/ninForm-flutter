import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() {
  runApp(const NinVerifierApp());
}

class NinVerifierApp extends StatelessWidget {
  const NinVerifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIN Verification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const NinVerifierPage(),
    );
  }
}

class NinVerifierPage extends StatefulWidget {
  const NinVerifierPage({super.key});

  @override
  State<NinVerifierPage> createState() => _NinVerifierPageState();
}

class _NinVerifierPageState extends State<NinVerifierPage> {
  final _ninFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();

  final _ninController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _lgaController = TextEditingController();
  final _townController = TextEditingController();
  final _schoolController = TextEditingController();

  bool _loading = false;
  String? _error;
  VerifiedProfile? _profile;

  // ========== CONFIG ==========
  static const String VERIFY_API_URL = ""; // your NIN API/proxy
  static const String SUBMIT_SHEET_URL = "https://nin-proxy-1.onrender.com/submit"; // your Apps Script endpoint
  // ============================

  @override
  void dispose() {
    _ninController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _lgaController.dispose();
    _townController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _verifyNin() async {
    if (!_ninFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
    });

    final nin = _ninController.text.trim();

    try {
      if (VERIFY_API_URL.isEmpty) {
        // 🔹 Mock response for demo
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _profile = VerifiedProfile(
            nin: nin,
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: "1990-01-01",
            gender: "Male",
            verified: true,
          );
          _loading = false;
        });
        return;
      }

      final resp = await http.post(
        Uri.parse(VERIFY_API_URL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nin": nin}),
      );

      if (resp.statusCode != 200) {
        throw Exception("API error: ${resp.statusCode}");
      }

      final data = jsonDecode(resp.body);
      setState(() {
        _profile = VerifiedProfile.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) print("verify error: $e");
      setState(() {
        _loading = false;
        _error = "Verification failed: $e";
      });
    }
  }

  Future<void> _submitToSheet() async {
    if (_profile == null) return;
    if (!_detailsFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        ..._profile!.toJson(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "localGovernment": _lgaController.text.trim(),
        "town": _townController.text.trim(),
        "school": _schoolController.text.trim(),
      };

      if (SUBMIT_SHEET_URL.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 700));
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✔️ Saved (mock)")),
        );
        return;
      }

      final resp = await http.post(
        Uri.parse("https://cors-anywhere.herokuapp.com/$SUBMIT_SHEET_URL"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception("Submit error: ${resp.statusCode}");
      }

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✔️ Saved to Google Sheet")),
      );
    } catch (e) {
      if (kDebugMode) print("submit error: $e");
      setState(() {
        _loading = false;
        _error = "Submission failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NIN Verification")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // NIN input
                Form(
                  key: _ninFormKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ninController,
                          decoration: const InputDecoration(
                            labelText: "Enter NIN",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "NIN is required";
                            }
                            if (value.length != 11 ||
                                int.tryParse(value) == null) {
                              return "NIN must be 11 digits";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _verifyNin,
                        icon: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: const Text("Verify"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Error
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),

                // Profile & form
                if (_profile != null) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _detailsFormKey,
                        child: Column(
                          children: [
                            _lockedField("First Name", _profile!.firstName),
                            _lockedField("Last Name", _profile!.lastName),
                            _lockedField("Date of Birth", _profile!.dateOfBirth),
                            _lockedField("Gender", _profile!.gender),
                            const Divider(),
                            _editableField(
                              "Email",
                              _emailController,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Email is required";
                                }
                                final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!regex.hasMatch(v)) {
                                  return "Invalid email";
                                }
                                return null;
                              },
                            ),
                            _editableField(
                              "Phone Number",
                              _phoneController,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Phone number is required";
                                }
                                if (v.length < 10 || v.length > 15) {
                                  return "Phone must be 10-15 digits";
                                }
                                if (int.tryParse(v) == null) {
                                  return "Phone must be digits only";
                                }
                                return null;
                              },
                            ),
                            _editableField(
                              "Address",
                              _addressController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Address is required" : null,
                            ),
                            _editableField(
                              "Local Government",
                              _lgaController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Local Government is required" : null,
                            ),
                            _editableField(
                              "Town",
                              _townController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Town is required" : null,
                            ),
                            _editableField(
                              "Name of School",
                              _schoolController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "School is required" : null,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _submitToSheet,
                              icon: const Icon(Icons.save),
                              label: const Text("Save to Sheet"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value ?? "",
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _editableField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class VerifiedProfile {
  final String? nin;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final bool verified;

  VerifiedProfile({
    this.nin,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    required this.verified,
  });

  factory VerifiedProfile.fromJson(Map<String, dynamic> json) {
    return VerifiedProfile(
      nin: json['nin']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      verified: json['verified'] == true || json['status'] == "verified",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nin": nin,
      "firstName": firstName,
      "lastName": lastName,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "verified": verified,
    };
  }
}
