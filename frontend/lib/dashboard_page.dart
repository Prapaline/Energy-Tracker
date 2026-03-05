import 'package:flutter/material.dart';
import 'package:frontend/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'add_consumption_page.dart';
import 'dart:html' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

Widget _buildDropdown({
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8FF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: items
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
    ),
  );
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> consumptions = [];
  String filterType = "Tous";
  String period = "Jour";
  String username = "";


  @override
  void initState() {
    super.initState();
    fetchUser();
    fetchConsumptions();
  }

  Future<void> uploadCsv() async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) async {
        final bytes = reader.result as List<int>;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:8080/consumptions/upload'),
        );

        const storage = FlutterSecureStorage();
        String? token = await SecureStorage.readToken();


        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );

        final response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Import réussi")),
          );
          fetchConsumptions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur import")),
          );
        }
      });
    });
  }
  String getLabel(String key) {
    DateTime date = DateTime.parse(key);
    switch (period) {
      case "Jour":
        return "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}";
      case "Mois":
        return "${date.month.toString().padLeft(2,'0')}/${date.year}";
      case "Année":
        return "${date.year}";
      default:
        return "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}";
    }
  }


  Future<void> fetchUser() async {
    try {
      String? token = await SecureStorage.readToken();
      print("TOKEN UTILISÉ POUR /me : $token");

      if (token == null) {
        print("Token manquant, utilisateur non connecté");
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("STATUS /me : ${response.statusCode}");

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        setState(() {
          username = user['username'];
        });
      } else {
        print("Erreur récupération user : ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception fetchUser: $e");
    }
  }

  Future<void> fetchConsumptions() async {

    String? token = await SecureStorage.readToken();

    if (token == null) {
      print("Token null !");
      return;
    }

    print("Token envoyé : $token");

    final response = await http.get(
      Uri.parse('http://localhost:8080/consumptions/my'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    print("Status code : ${response.statusCode}");
    print("Body : ${response.body}");

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(body);

      setState(() {
        consumptions = data;
      });
    }
  }



  Map<String, double> aggregateData() {
    Map<String, double> data = {};
    for (var c in consumptions) {
      String type = c['type'];
      DateTime date = DateTime.parse(c['date']);
      String key;
      switch (period) {
        case "Jour":
          key = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
          break;
        case "Mois":
        //Premier jour du mois
          key = "${date.year}-${date.month.toString().padLeft(2,'0')}-01";
          break;
        case "Année":
        //Premier jour de l'année
          key = "${date.year}-01-01";
          break;
        default:
          key = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
      }



      if (filterType != "Tous" && type.toLowerCase() != filterType.toLowerCase()) continue;


      if (data.containsKey(key)) {
        data[key] = data[key]! + c['value'];
      } else {
        data[key] = c['value'] * 1.0;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final aggregated = aggregateData();
    final sortedKeys = aggregated.keys.toList()..sort();

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bonjour, $username 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Suivi de vos consommations",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        //Supprimer le token
                        await SecureStorage.deleteToken();

                        //Rediriger vers la page de login
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (route) => false,
                        );
                      },
                    )
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [

                      //filtre
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDropdown(
                            value: filterType,
                            items: ["Tous", "Eau", "Électricité", "Gaz"],
                            onChanged: (val) {
                              setState(() {
                                filterType = val!;
                              });
                            },
                          ),
                          _buildDropdown(
                            value: period,
                            items: ["Jour", "Mois", "Année"],
                            onChanged: (val) {
                              setState(() {
                                period = val!;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: fetchConsumptions,
                          )
                        ],
                      ),

                      const SizedBox(height: 25),

                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: aggregated.isEmpty
                            ? const Center(child: Text("Aucune donnée"))
                            : LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: (() {
                              final yValues = aggregated.values.toList();
                              if (yValues.isEmpty) return 1.0;
                              return yValues.reduce((a, b) => a > b ? a : b) * 1.2;
                            })(),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                bottom: BorderSide(color: Colors.black12),
                                left: BorderSide(color: Colors.black12),
                                right: BorderSide(color: Colors.transparent),
                                top: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  sortedKeys.length,
                                      (i) => FlSpot(i.toDouble(), aggregated[sortedKeys[i]]!),
                                ),
                                isCurved: true,
                                barWidth: 4,
                                color: const Color(0xFF1565C0),
                                dotData: FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < sortedKeys.length) {
                                      int step = 1;
                                      if (period == "Jour") step = 2;
                                      if (period == "Mois") step = 1;
                                      if (period == "Année") step = 1;

                                      if (index % step == 0) {
                                        return Text(getLabel(sortedKeys[index]),
                                            style: const TextStyle(fontSize: 10));
                                      }
                                    }
                                    return const Text("");
                                  },

                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: (() {
                                    final yValues = aggregated.values.toList();
                                    if (yValues.isEmpty) return 1.0;
                                    double max = yValues.reduce((a, b) => a > b ? a : b) * 1.2;
                                    return max / 5; // 5 graduations
                                  })(),
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toStringAsFixed(0),
                                        style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 25),

                      Expanded(
                        child: ListView.builder(
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final key = sortedKeys[index];
                            final formattedLabel = getLabel(key); // <-- formater la date ici

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(Icons.bolt, color: Color(0xFF1565C0)),
                                title: Text(formattedLabel),
                                trailing: Text(
                                  "${aggregated[key]?.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text("Ajout manuel"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                 AddConsumptionPage(),
                          ),
                        ).then((_) => fetchConsumptions());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text("Importer un CSV"),
                      onTap: () async {
                        Navigator.pop(context);
                        await uploadCsv();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

}
