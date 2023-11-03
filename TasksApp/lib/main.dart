import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'Screens/BookTicketScreen.dart';
// import 'Screens/ShowTicketScreen.dart';
// import 'Screens/PlatformBooking.dart';
// import 'Screens/HomeScreen.dart';
// import 'Screens/TravelBookingScreen.dart';
import 'firebase_options.dart';
// import 'Screens/PaymentScreen.dart';
// import 'Screens/paymentScreen2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await Firebase.initializeApp(
  //   options: DefaultFirebsaseOptions.currentPlatform,
  // );
  runApp(MyApp());
  // runApp(TasksApp(appRouter: AppRoute()));
  // runApp(
  //   MaterialApp(
  //     initialRoute: '/',
  //     routes: {
  //       '/': (context) => HomeScreen(), // Home screen
  //       '/bookTicket': (context) => BookTicketScreen(), // Book Ticket screen
  //       '/showTicket': (context) => ShowTicketScreen(), // Show Ticket screen
  //       '/platformBooking': (context) =>
  //           PlatformBookingScreen(), //platform ticket
  //       '/travelBooking': (context) => TravelBookingScreen(),
  //       '/paymentScreen': (context) => PaymentScreen(),
  //       '/paymentScreen2': (context) => PaymentScreen2(),
  //     },
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController DesController = TextEditingController();
  final TextEditingController ClassController = TextEditingController();
  final TextEditingController TypeController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController numId = TextEditingController();
  List<String> idList = [];

  final firestoreInstance = FirebaseFirestore.instance;

  Future<void> _displayData() async {
    final usersCollection = await firestoreInstance.collection('users').get();
    final userData = usersCollection.docs;

    // Create a formatted string to display the data
    final displayText = userData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value.data() as Map<String, dynamic>;
      final source = data['Source'];
      final destination = data['Destination'];
      final clas = data['class'];
      final typ = data['type'];

      return '''
        Ticket - ${index + 1}:
        Source: $source
        Destination: $destination
        Class: $clas
        Type: $typ

      ''';
    }).join('\n');

    // Display the data in an alert dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Text('User Data'),
          content: Text(displayText),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _submitData() async {
    final src = sourceController.text;
    final des = DesController.text;
    final clas = ClassController.text;
    final typ = TypeController.text;

    // Store data in Firestore
    await firestoreInstance.collection('users').add({
      'Source': src,
      'Destination': des,
      'class': clas,
      'type': typ,
    });

    for (final id in idList) {
      // Create a new collection with the ID as its name
      final newCollection = firestoreInstance.collection(id);

      // Add a document within the new collection
      await newCollection.add({
        'Source': src,
        'Destination': des,
        'class': clas,
        'type': typ,
      });
    }

    // Clear the input fields and ID list
    sourceController.clear();
    DesController.clear();
    ClassController.clear();
    TypeController.clear();
    idController.clear();
    idList.clear();
  }

  void _addId() {
    final newId = idController.text;
    if (newId.isNotEmpty && idList.length < 4) {
      setState(() {
        idList.add(newId);
        idController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: sourceController,
              decoration: InputDecoration(labelText: 'Source'),
            ),
            TextField(
              controller: DesController,
              decoration: InputDecoration(labelText: 'Destination'),
            ),
            TextField(
              controller: ClassController,
              decoration: InputDecoration(labelText: 'Class'),
            ),
            TextField(
              controller: TypeController,
              decoration: InputDecoration(labelText: 'Type'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: numId,
              decoration:
                  InputDecoration(labelText: 'Enter The Number of Ticket'),
              keyboardType: TextInputType.number,
            ),
            Text('Enter $numId IDs'),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: idController,
                    decoration: InputDecoration(labelText: 'ID'),
                    // Accept only numbers
                  ),
                ),
                ElevatedButton(
                  onPressed: _addId,
                  child: Text('Add ID'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('Entered IDs: ${idList.join(', ')}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _displayData,
              child: Text('Display'),
            ),
          ],
        ),
      ),
    );
  }
}
