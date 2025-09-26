import 'dart:convert';
import 'dart:developer';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

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
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
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
  final _middleName = TextEditingController();
  final _placeOfBirth = TextEditingController();
  final _lgaOfBirth = TextEditingController();
  final _lgaOfOrigin = TextEditingController();
  final _stateOfOrigin = TextEditingController();
  final _motherMaiden = TextEditingController();
  final _residentialAddress = TextEditingController();
  final _hostelAddress = TextEditingController();
  final _school = TextEditingController();
  final _faculty = TextEditingController();
  final _department = TextEditingController();
  final _academicLevel = TextEditingController();

  // File uploads
  final Map<String, PlatformFile?> _uploads = {
    "lgaCertificate": null,
    "birthCertificate": null,
    "admissionLetter": null,
    "studentId": null,
    "lastResult": null,
    "passportPhoto": null,
    "ninCard": null,
  };
  bool _loading = false;
  String? _error;
  VerifiedProfile? _profile;

  // ========== CONFIG ==========
  static const String VERIFY_API_URL = ""; // your NIN API/proxy
  static const String SUBMIT_SHEET_URL =
      "https://nin-proxy-1.onrender.com/submit"; // your Apps Script endpoint
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

  final Map<String, String> _fileLabels = {
    "lgaCertificate": "LGA of Origin Certificate",
    "birthCertificate": "Birth Certificate",
    "admissionLetter": "Admission Letter",
    "studentId": "Student ID",
    "lastResult": "Last School Result",
    "passportPhoto": "Passport Photo *",
    "ninCard": "NIN Card *",
  };

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
Future<Map<String, dynamic>> encodeFileWeb(PlatformFile? file) async {
  if (file == null || file.bytes == null) return {};

  final mimeType = lookupMimeType(file.name) ?? "application/octet-stream";

  return {
    "base64": base64Encode(file.bytes!), // convert Uint8List -> base64 string
    "mimeType": mimeType,
    "fileName": file.name,
  };
}
  Future<void> _submit() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    // 🔹 Check required uploads
    final requiredFiles = ["passportPhoto", "ninCard"];
    for (final key in requiredFiles) {
      if (_uploads[key] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Please upload ${_fileLabels[key]}")),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      // Convert files to base64
      final Map<String, String?> fileData = {};
      _uploads.forEach((key, file) {
        if (file != null && file.bytes != null) {
          fileData[key] = base64Encode(file.bytes!);
        }
      });

      final payload = {
        "nin": _ninController.text,
        "firstName": _profile!.firstName,
        "lastName": _profile!.lastName,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "dateOfBirth": _profile!.dateOfBirth,
        "gender": _profile!.gender,
        "middleName": _middleName.text,
        "placeOfBirth": _placeOfBirth.text,
        "lgaOfBirth": _lgaOfBirth.text,
        "lgaOfOrigin": _lgaOfOrigin.text,
        "stateOfOrigin": _stateOfOrigin.text,
        "motherMaidenName": _motherMaiden.text,
        "residentialAddress": _residentialAddress.text,
        "hostelAddress": _hostelAddress.text,
        "school": _school.text,
        "faculty": _faculty.text,
        "department": _department.text,
        "academicLevel": _academicLevel.text,
        // 🔹 Attachments as separate fields
  // "lgaCertificate": await encodeFileWeb(_uploads["lgaCertificate"]),
  // "birthCertificate": await encodeFileWeb(_uploads["birthCertificate"]),
  // "admissionLetter": await encodeFileWeb(_uploads["admissionLetter"]),
  // "studentId": await encodeFileWeb(_uploads["studentId"]),
  // "lastResult": await encodeFileWeb(_uploads["lastResult"]),
  // "passportPhoto": await encodeFileWeb(_uploads["passportPhoto"]),
  // "ninCard": await encodeFileWeb(_uploads["ninCard"]),
      };

      final resp = await http.post(
        Uri.parse("$SUBMIT_SHEET_URL"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception("Submit error: ${resp.statusCode}");
      }

      log(resp.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✔️ Submitted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Submission failed: $e")));
    } finally {
      setState(() => _loading = false);
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
                        icon:
                            _loading
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
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
                            _lockedField(
                              "Date of Birth",
                              _profile!.dateOfBirth,
                            ),
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
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Address is required"
                                          : null,
                            ),
                            _editableField(
                              "Local Government",
                              _lgaController,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Local Government is required"
                                          : null,
                            ),
                            _editableField(
                              "Town",
                              _townController,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Town is required"
                                          : null,
                            ),
                            _editableField(
                              "Name of School",
                              _schoolController,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "School is required"
                                          : null,
                            ),
                            const Divider(),
                            // 🔹 Other editable fields
                            _editableField(
                              "Middle Name",
                              _middleName,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Middle Name is required"
                                          : null,
                            ),
                            _editableField(
                              "Place of Birth",
                              _placeOfBirth,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Place of Birth is required"
                                          : null,
                            ),
                            _editableField(
                              "LGA of Birth",
                              _lgaOfBirth,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "LGA of Birth is required"
                                          : null,
                            ),
                            _editableField(
                              "LGA of Origin",
                              _lgaOfOrigin,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "LGA of Origin is required"
                                          : null,
                            ),
                            _editableField(
                              "State of Origin",
                              _stateOfOrigin,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "State of Origin is required"
                                          : null,
                            ),
                            _editableField(
                              "Mother’s Maiden Name",
                              _motherMaiden,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Mother’s Maiden Name is required"
                                          : null,
                            ),
                            _editableField(
                              "Residential Address",
                              _residentialAddress,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Residential Address is required"
                                          : null,
                            ),
                            _editableField(
                              "School/Hostel Address",
                              _hostelAddress,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "School/Hostel Address is required"
                                          : null,
                            ),
                            _editableField(
                              "Name of School",
                              _school,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Name of School is required"
                                          : null,
                            ),
                            _editableField(
                              "Faculty",
                              _faculty,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Faculty is required"
                                          : null,
                            ),
                            _editableField(
                              "Department",
                              _department,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Department is required"
                                          : null,
                            ),
                            _editableField(
                              "Academic Level",
                              _academicLevel,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? "Academic Level is required"
                                          : null,
                            ),
                            const Divider(),
                            const Text(
                              "📎 Attachments",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            // 🔹 File upload fields with labels
                            _fileField(
                              "LGA of Origin Certificate",
                              "lgaCertificate",
                            ),
                            _fileField("Birth Certificate", "birthCertificate"),
                            _fileField("Admission Letter", "admissionLetter"),
                            _fileField("Student ID Card", "studentId"),
                            _fileField("Last School Result", "lastResult"),
                            _fileField("Passport Photo", "passportPhoto"),
                            _fileField("NIN Card", "ninCard"),

                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _submit,
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

  Widget _fileField(String label, String key) {
    final file = _uploads[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              file?.name ?? "$label not selected",
              style: TextStyle(
                color: file == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _pickFile(key),
            child: Text(file == null ? "Upload" : "Change"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(String key) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true, // ensures we get file bytes
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploads[key] = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to pick file: $e")));
    }
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
