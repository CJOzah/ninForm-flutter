import 'dart:convert';
import 'dart:developer';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';  

Future<void> main() async { 
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

final _emailController = TextEditingController();
  final _ninController = TextEditingController(); 
  final _addressController = TextEditingController(); 
  final _townController = TextEditingController(); 
  final _placeOfBirth = TextEditingController();  
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
  static const String VERIFY_API_URL = 
  
      "https://nin-proxy-1.onrender.com/checkNin"; // your NIN API/proxy
  static const String SUBMIT_SHEET_URL = 
      "https://nin-proxy-1.onrender.com/submit"; // your Apps Script endpoint
  // ============================

  @override
  void dispose() {
    _ninController.dispose(); 
    _addressController.dispose(); 
    _townController.dispose(); 
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
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: "1990-01-01",
            email: "jj@qa.team",
            mobile: "09055453423",
            middleName: "eric",
            birthLGA: "Ughelli South",
            birthState: "Delta State",
            gender: "Male",
            verified: true,
          );
          log("profile ${_profile!.toJson()}");
          _loading = false;
        });
        return;
      }

      log("Request ${VERIFY_API_URL}");

      final resp = await http.post(
        Uri.parse(VERIFY_API_URL),
        headers: {"Content-Type": "application/json", },
        body: jsonEncode({
          "id": nin,
          "premiumNin": true,
          "isSubjectConsent": true,
        }),
      );

      if (resp.statusCode != 200) {
        throw Exception("API error: ${resp.statusCode}");
      }
      log("NIN res ${resp.body}");

      final data = jsonDecode(resp.body)['data'];
      setState(() {
        // if (VerifiedProfile.fromJson(
        //       data,
        //     ).birthState!.toLowerCase().contains("delta") ==
        //     false) {
        //   _loading = false;

        //   ScaffoldMessenger.of(
        //     context,
        //   ).showSnackBar(SnackBar(content: Text("You do not qualify")));
        //   return;
        // }
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

  Future<void> _submit() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Convert files to base64
      final Map<String, dynamic> fileData = {};
      for (final entry in _uploads.entries) {
        if (entry.value != null && entry.value!.bytes != null) {
          fileData[entry.key] = {
            "base64": base64Encode(entry.value!.bytes!),
            "fileName": entry.value!.name,
            "mimeType":
                entry.value!.extension == "pdf"
                    ? "application/pdf"
                    : "image/jpeg",
          };
        }
      }

      final payload = {
        "nin": _ninController.text,
        "firstName": _profile!.firstName,
        "middleName": _profile!.middleName,
        "lastName": _profile!.lastName,
        "email": _profile!.email,
        "phone": _profile!.mobile,
        "dateOfBirth": _profile!.dateOfBirth,
        "gender": _profile!.gender,
        "placeOfBirth": _placeOfBirth.text,
        "lgaOfOrigin": _profile!.birthLGA, 
        "stateOfOrigin": _profile!.birthState,
        "motherMaidenName": _motherMaiden.text,
        "residentialAddress": _residentialAddress.text,
        "hostelAddress": _hostelAddress.text,
        "school": _school.text,
        "faculty": _faculty.text,
        "department": _department.text,
        "academicLevel": _academicLevel.text,

        "passportPhoto":
            _uploads["passportPhoto"] != null
                ? await encodeFileWeb(_uploads["passportPhoto"]!)
                : null,
        "ninCard":
            _uploads["ninCard"] != null
                ? await encodeFileWeb(_uploads["ninCard"]!)
                : null,

        "lgaCertificate":
            _uploads["lgaCertificate"] != null
                ? await encodeFileWeb(_uploads["lgaCertificate"]!)
                : null,
        "birthCertificate":
            _uploads["birthCertificate"] != null
                ? await encodeFileWeb(_uploads["birthCertificate"]!)
                : null,
        "admissionLetter":
            _uploads["admissionLetter"] != null
                ? await encodeFileWeb(_uploads["admissionLetter"]!)
                : null,
        "studentId":
            _uploads["studentId"] != null
                ? await encodeFileWeb(_uploads["studentId"]!)
                : null,
        "lastResult":
            _uploads["lastResult"] != null
                ? await encodeFileWeb(_uploads["lastResult"]!)
                : null,
      };

 
      final resp = await http.post(
        Uri.parse("$SUBMIT_SHEET_URL"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception("Submit error: ${resp.statusCode}");
      }

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

  Future<Map<String, dynamic>> encodeFileWeb(PlatformFile file) async {
    Uint8List? compressedBytes;
 
      compressedBytes = file.bytes; // leave PDFs untouched
    

    return {
      "base64": base64Encode(compressedBytes!),
      "fileName": file.name,
      "mimeType": file.extension == "pdf" ? "application/pdf" : "image/jpeg",
    };
  }

  @override
  Widget build(BuildContext context) {

      log("NIN res ${_profile?.firstName}");
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
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _detailsFormKey,
                      child: Column(
                        children: [
                          if (_profile != null)
                            _lockedField("First Name", _profile!.firstName), 
                          if (_profile != null)
                            _lockedField("Last Name", _profile!.lastName),
                          if (_profile != null)
                            _lockedField(
                              "Date of Birth",
                              _profile!.dateOfBirth,
                            ),
                          if (_profile != null)
                            _lockedField("Gender", _profile!.gender), 
                          if (_profile != null)
                            _lockedField("Phone Number", _profile!.mobile),
                          if (_profile != null)
                            _lockedField("Middle Name", _profile!.middleName),
                          if (_profile != null)
                            _lockedField("LGA of Origin", _profile!.birthLGA),
                          if (_profile != null)
                            _lockedField(
                              "State of Origin",
                              _profile!.birthState,
                            ),
                          if (_profile != null)
 _editableField(
                            "Email",
                          _profile!.email!.isEmpty ? _emailController  : TextEditingController(text:  _profile!.email),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Email is required"
                                        : null,
                          ),
                            const Divider(),
 
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
                            "Town",
                            _townController,
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Town is required"
                                        : null,
                          ), 
                          const Divider(),
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
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? mobile;
  final String? email;
  final String? birthState;
  final String? birthLGA;
  final bool verified;

  VerifiedProfile({ 
    this.firstName,
    this.mobile,
    this.email,
    this.birthState,
    this.birthLGA,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    required this.verified,
  });

  factory VerifiedProfile.fromJson(Map<String, dynamic> json) {
    return VerifiedProfile( 
      firstName: json["firstName"] ?? "N/A",
      middleName: json["middleName"] ?? "N/A",
      birthLGA: json['address']["lga"] ?? "N/A",
      birthState: json['address']["state"] ?? "N/A",
      email: json["email"] ?? "N/A",
      mobile: json["mobile"] ?? "N/A",
      lastName: json['lastName'] ?? "N/A",
      dateOfBirth: json["dateOfBirth"] ?? "N/A",
      gender: json["gender"] ?? "N/A",
      verified:
          json['allValidationPassed'] == true ||
          json['status'] == "allValidationPassed",
    );
  }

  Map<String, dynamic> toJson() {
    return { 
      "firstName": firstName,
      "lastName": lastName,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "verified": verified,
      "middleName": middleName,
      "birthLGA": birthLGA,
      "birthState": birthState,
      "email": email,
      "mobile": mobile,
    };
  }
}
