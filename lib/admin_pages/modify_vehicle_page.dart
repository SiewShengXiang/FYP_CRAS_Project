import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fyp_cras/cars/car_body_type.dart';
import 'package:fyp_cras/cars/car_brand_list.dart';
import 'package:fyp_cras/cars/car_segment.dart';
import 'package:image_picker/image_picker.dart';

class ModifyVehiclePage extends StatefulWidget {
  final DocumentSnapshot document;

  const ModifyVehiclePage({super.key, required this.document});

  @override
  _ModifyVehiclePageState createState() => _ModifyVehiclePageState();
}

class _ModifyVehiclePageState extends State<ModifyVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBrand;
  String? _selectedBodyType;
  String? _selectedSegment;
  String? _price;
  String? _model;
  String? _imageUrl;
  File? _image;
  bool _available = false; // Added boolean for availability

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.document['brand'];
    _selectedBodyType = widget.document['bodyType'];
    _selectedSegment = widget.document['segment'];
    _price = widget.document['price'];
    _model = widget.document['model'];
    _imageUrl = widget.document['imageUrl'];
    _available = widget.document['available'] ??
        false; // Set initial value for availability
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void modifyCar(String model, String brand, String bodyType, String segment,
      String price, String documentId, bool available) async {
    String imageUrl = _imageUrl!;
    if (_image != null) {
      // Delete the old image from Firebase Storage
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final Reference oldImageRef =
            FirebaseStorage.instance.refFromURL(_imageUrl!);
        await oldImageRef.delete();
      }

      // Upload the new image
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('files/${_image!.path.split('/').last}');
      final UploadTask uploadTask = storageReference.putFile(_image!);
      final TaskSnapshot downloadUrl = await uploadTask.whenComplete(() {});
      imageUrl = await downloadUrl.ref.getDownloadURL();
    }

    FirebaseFirestore.instance.collection('Cars').doc(documentId).update({
      'model': model,
      'brand': brand,
      'bodyType': bodyType,
      'segment': segment,
      'price': price,
      'imageUrl': imageUrl, // Update image URL if image changed
      'available': available, // Update availability
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Vehicle'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: getImage,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _image == null
                            ? (_imageUrl != null
                                ? Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Text('Tap to select image'))
                            : Image.file(_image!),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: Text(
                                'Click to Modify',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Model',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _model = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a model';
                    }
                    return null;
                  },
                  initialValue: _model,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                  ),
                  value: _selectedBrand,
                  onChanged: (value) {
                    setState(() {
                      _selectedBrand = value;
                    });
                  },
                  items: carBrands.map((brand) {
                    return DropdownMenuItem<String>(
                      value: brand.name,
                      child: Text(brand.name),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Body Type',
                  ),
                  value: _selectedBodyType,
                  onChanged: (value) {
                    setState(() {
                      _selectedBodyType = value;
                    });
                  },
                  items: bodyTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.name,
                      child: Text(type.name),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Segment',
                  ),
                  value: _selectedSegment,
                  onChanged: (value) {
                    setState(() {
                      _selectedSegment = value;
                    });
                  },
                  items: segments.map((segment) {
                    return DropdownMenuItem<String>(
                      value: segment.name,
                      child: Text(segment.name),
                    );
                  }).toList(),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _price = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                  initialValue: _price,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Available:'),
                    const Spacer(), // Add Spacer widget
                    Checkbox(
                      value: _available,
                      onChanged: (value) {
                        setState(() {
                          _available = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        modifyCar(
                          _model ?? '',
                          _selectedBrand ?? '',
                          _selectedBodyType ?? '',
                          _selectedSegment ?? '',
                          _price ?? '',
                          widget.document.id,
                          _available,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple[700],
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Modify Vehicle'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
