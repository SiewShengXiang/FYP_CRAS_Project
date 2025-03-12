import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fyp_cras/cars/car_body_type.dart';
import 'package:fyp_cras/cars/car_brand_list.dart';
import 'package:fyp_cras/cars/car_segment.dart';
import 'package:image_picker/image_picker.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBrand;
  String? _selectedBodyType;
  String? _selectedSegment;
  String? _price;
  String? _model;
  File? _image;
  bool _available = true; // Default to true, meaning available
  bool _isLoading = false; // Loading state

  final picker = ImagePicker();

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

  Future<void> addCar(String model, String brand, String bodyType,
      String segment, String price) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    if (_image == null) {
      print('No image selected.');
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    final Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('files/${_image!.path.split('/').last}');
    final UploadTask uploadTask = storageReference.putFile(_image!);
    final TaskSnapshot downloadUrl = await uploadTask.whenComplete(() {});
    final String url = await downloadUrl.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('Cars').add({
      'model': model,
      'brand': brand,
      'bodyType': bodyType,
      'segment': segment,
      'price': price,
      'imageUrl': url,
      'available': _available, // Include availability status
    });

    // Clear the form and reset state
    _formKey.currentState!.reset();
    setState(() {
      _selectedBrand = null;
      _selectedBodyType = null;
      _selectedSegment = null;
      _price = null;
      _model = null;
      _image = null;
      _available = true; // Reset to default
      _isLoading = false; // Stop loading
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle added successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // assign _formKey here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _image == null
                    ? const Text('No image selected.')
                    : Image.file(_image!),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.purple[700],
                ),
                child: TextButton(
                  onPressed: getImage,
                  child: const Text(
                    'Select Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
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
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available:'),
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
                      addCar(
                        _model ?? '',
                        _selectedBrand ?? '',
                        _selectedBodyType ?? '',
                        _selectedSegment ?? '',
                        _price ?? '',
                      );
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
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
