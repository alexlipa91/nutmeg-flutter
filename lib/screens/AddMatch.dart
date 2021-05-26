import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/models/Model.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(new MaterialApp(home: AddMatch()));
}

class AddMatch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddMatchState();
}

class AddMatchState extends State<AddMatch> {
  SportCenter sportCenter;
  Sport sport = Sport.fiveAsideFootball;
  TextEditingController dateController = new TextEditingController();
  TextEditingController priceController = new TextEditingController();
  int maxPlayers = 10;

  @override
  Widget build(BuildContext context) {
    CollectionReference matches =
        FirebaseFirestore.instance.collection('matches');

    return Scaffold(
        body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Choose date and time",
                    style: new TextStyle(color: Colors.blue)),
                DateTimePicker(
                  type: DateTimePickerType.dateTimeSeparate,
                  dateMask: 'd MMM, yyyy',
                  // initialValue: DateTime.now().toString(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  icon: Icon(Icons.event),
                  dateLabelText: 'Date',
                  timeLabelText: "Hour",
                  onChanged: (val) => print(val),
                  onSaved: (val) => print(val),
                  controller: dateController,
                ),
                SizedBox(height: 30.0),
                Text("Choose SportCenter",
                    style: new TextStyle(color: Colors.blue)),
                DropdownButton<SportCenter>(
                  focusColor: Colors.white,
                  value: sportCenter,
                  //elevation: 5,
                  style: TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.black,
                  items: SportCenter.getSportCenters()
                      .map<DropdownMenuItem<SportCenter>>((SportCenter value) {
                    return DropdownMenuItem<SportCenter>(
                        value: value,
                        child: Text(value.getName() == null ? "null" : value.getName(),
                            style: TextStyle(color: Colors.black)));
                  }).toList(),
                  onChanged: (SportCenter value) {
                    setState(() {
                      sportCenter = value;
                    });
                  },
                ),
                SizedBox(height: 30.0),
                Text("Choose sport", style: new TextStyle(color: Colors.blue)),
                DropdownButton<Sport>(
                  focusColor: Colors.white,
                  value: sport,
                  //elevation: 5,
                  style: TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.black,
                  items:
                      Sport.values.map<DropdownMenuItem<Sport>>((Sport value) {
                    return DropdownMenuItem<Sport>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(color: Colors.black)));
                  }).toList(),
                  onChanged: (Sport value) {
                    setState(() {
                      sport = value;
                    });
                  },
                ),
                SizedBox(height: 30.0),
                Text("Price per person (in euro)",
                    style: new TextStyle(color: Colors.blue)),
                TextFormField(
                  controller: priceController,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                ),
                SizedBox(height: 30.0),
                Text("Max players", style: new TextStyle(color: Colors.blue)),
                DropdownButton<int>(
                  focusColor: Colors.white,
                  value: maxPlayers,
                  //elevation: 5,
                  style: TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.black,
                  items:
                      [8, 10, 12, 14].map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString(),
                            style: TextStyle(color: Colors.black)));
                  }).toList(),
                  onChanged: (int value) {
                    setState(() {
                      maxPlayers = value;
                    });
                  },
                ),
                TextButton(
                    onPressed: () {
                      if (dateController.value.text == "" ||
                          sportCenter == null ||
                          priceController.value.text == "") {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                  content: Text("Please fill all fields"));
                            });
                      } else {
                        //todo
                        print("adding");
                        var m = Match(
                            DateTime.parse(dateController.value.text),
                            sportCenter,
                            sport,
                            maxPlayers,
                            [],
                            double.parse(priceController.value.text),
                            MatchStatus.open);

                        matches
                            .add(m.toJson())
                            .then((value) => showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      content: Text("Match added"));
                                }))
                            .catchError((error) => showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      content:
                                          Text("Failed: " + error.toString()));
                                }));
                      }
                    },
                    child: Text("Add"))
              ],
            )));
  }
}
