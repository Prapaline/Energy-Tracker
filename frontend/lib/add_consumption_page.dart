import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage.dart';
import 'package:flutter/services.dart';

class AddConsumptionPage extends StatefulWidget {
  @override
  _AddConsumptionPageState createState() => _AddConsumptionPageState();
}

class _AddConsumptionPageState extends State<AddConsumptionPage> {
  final _valueController = TextEditingController();
  String? selectedType;
  DateTime selectedDate = DateTime.now();
  String message = "";

  final List<String> types = ["Eau", "Électricité", "Gaz"];

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<String>(
        value: selectedType,
        hint: const Text("Sélectionnez le type"),
        isExpanded: true,
        underline: const SizedBox(),
        items: types
            .map(
              (type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          ),
        )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedType = value;
          });
        },
      ),
    );
  }

  Future<void> addConsumption() async {
    if (selectedType == null || _valueController.text.isEmpty) {
      setState(() {
        message = "Remplissez tous les champs";
      });
      return;
    }

    // ✅ Vérifier que la date n'est pas dans le futur
    if (selectedDate.isAfter(DateTime.now())) {
      setState(() {
        message = "La date ne peut pas être dans le futur";
      });
      return;
    }

    String? token = await SecureStorage.readToken();
    if (token == null || token.isEmpty) {
      setState(() {
        message = "Utilisateur non authentifié";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/consumptions/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "type": selectedType,
          "value": double.parse(_valueController.text),
          "date": selectedDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          message = "Consommation ajoutée avec succès !";
        });
        Navigator.pop(context);
      } else if (response.statusCode == 403) {
        setState(() {
          message = "Accès refusé : vérifiez votre connexion";
        });
      } else {
        setState(() {
          message = "Erreur ${response.statusCode} : ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Erreur réseau : $e";
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Nouvelle consommation",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Type d'énergie",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(),
                        const SizedBox(height: 25),
                        const Text(
                          "Valeur de consommation",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _valueController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.]?\d{0,2}')),
                            //autorise uniquement chiffres et un point
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.show_chart),
                            hintText: "Ex: 120.5",
                            filled: true,
                            fillColor: const Color(0xFFF4F8FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        const Text(
                          "Date",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "${selectedDate.day.toString().padLeft(2, '0')}/"
                                        "${selectedDate.month.toString().padLeft(2, '0')}/"
                                        "${selectedDate.year}"
                                ),
                                const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: addConsumption,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text("Ajouter la consommation", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: message.contains("succès") ? Colors.green : Colors.red,
                            ),
                          ),
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
    );
  }
}
