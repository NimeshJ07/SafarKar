import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wallet/pages/createWallet.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:wallet/utilities/firestore.dart';

import 'package:wallet/utilities/sign_in_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  String privAddress = "";
  EthereumAddress targetAddress =
      EthereumAddress.fromHex("0x40c0F5117CA3D2C44800Fa34fec192271dCb3Bed");
  bool? created;
  var balance;
  var credentials;
  int myAmount = 4;
  var pro_pic;
  var u_name;

  String formatTokenBalance(BigInt balance) {
    int power = 18;
    BigInt divisor = BigInt.from(10).pow(power);
    BigInt wholePart = balance ~/ divisor;
    BigInt decimalPart = balance % divisor;
    String formattedBalance =
        "$wholePart.${decimalPart.toString().padLeft(power, '0').substring(0, 2)}";
    return formattedBalance;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://sepolia.infura.io/v3/4b2e7550998b47809ef8843eafc85e15",
        httpClient);
    details();
  }

  details() async {
    dynamic data = await getUserDetails();
    data != null
        ? setState(() {
            privAddress = data['privateKey'];
            var publicAdress = data['publicKey'];
            var temp = EthPrivateKey.fromHex(privAddress);
            credentials = temp.address;
            // EthPrivateKey fromHex = EthPrivateKey.fromHex(privAddress);
            // final password = FirebaseAuth.instance.currentUser!.uid;
            // Random random=Random.secure();
            // Wallet wallet = Wallet.createNew(fromHex, password,random);
            // print(wallet.toJson());
            created = data['wallet_created'];
            balance = getBalance(credentials);
            print(publicAdress);
          })
        : print("Data is NULL!");
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi/abi.json");

    String contractAddress = "0xf076201068e30D41d6551CbD2De7020eB0A0e1c0";
    final contract = DeployedContract(ContractAbi.fromJson(abi, "Rail2Connect"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance(EthereumAddress credentialAddress) async {
    List<dynamic> result = await query("balanceOf", [credentialAddress]);
    var data = result[0];
    setState(() {
      balance = BigInt.parse(data.toString());
    });
    ;
  }

  Future<String> sendCoin() async {
    // var bigAmount = BigInt.from(myAmount);
    // var response = await submit("transfer", [targetAddress, bigAmount]);
    // print(response);
    // return response;
    var bigAmount = BigInt.from(myAmount) * BigInt.from(10).pow(18);
    ;
    var response = await submit("transfer", [targetAddress, bigAmount]);
    print("TRANSACTION ID: ");
    print(response);
    return response;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    EthPrivateKey key = EthPrivateKey.fromHex(privAddress);
    Transaction transaction = await Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
        maxGas: 100000);
    print(transaction.nonce);
    final result =
        await ethClient.sendTransaction(key, transaction, chainId: 11155111);
    return result;
  }

  Future<void> _confirmPayment() async {
    print("TOTAL AMOUNT TO BE SEND : $myAmount");
    var bigAmount1 = BigInt.from(myAmount) * BigInt.from(10).pow(18);
    if (balance == null || balance < bigAmount1) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Insufficient Balance'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'You do not have enough balance to make this transaction.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Payment'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Are you sure you want to buy ticket?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Confirm'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  var response = await sendCoin();
                  _showTransactionDialog(response);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showTransactionDialog(String response) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transaction Successful'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Transaction number: $response'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// NEW SHARING TOKEN CODE
  Future<void> _shareTokensDialog() async {
    TextEditingController addressController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Tokens'),
          content: Column(
            children: <Widget>[
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Wallet Address'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Share Tokens'),
              onPressed: () async {
                String address = addressController.text;
                int amount = int.tryParse(amountController.text) ?? 0;
                if (amount > 0 && address.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _confirmShareTokens(address, amount);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmShareTokens(String address, int amount) async {
    var bigAmount2 = BigInt.from(amount) * BigInt.from(10).pow(18);
    if (balance == null || balance < bigAmount2) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Insufficient Balance'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'You do not have enough balance to make this transaction.',
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Share Tokens'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Are you sure you want to share $amount tokens to $address?',
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Confirm'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _sendTokens(address, amount);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _sendTokens(String address, int amount) async {
    var bigAmount = BigInt.from(amount) * BigInt.from(10).pow(18);
    var response =
        await submit("transfer", [EthereumAddress.fromHex(address), bigAmount]);
    print(response);
    _showTransactionDialog(response);
  }

// END OF SHARING TOKEN CODE

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL == null) {
      pro_pic = "assets/images/logo.png";
    } else {
      pro_pic = user!.photoURL;
    }
    if (user?.displayName == null) {
      u_name = "User Name";
    } else {
      u_name = user!.displayName;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView(
          children: [
            Container(
              color: Colors.blue[600],
              height: 150,
              alignment: Alignment.center,
              child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(
                          image: NetworkImage(pro_pic), scale: 0.1))),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    u_name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final provider = Provider.of<GoogleSignInProvider>(
                          context,
                          listen: false);
                      provider.googleLogout();
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              height: 100,
              width: MediaQuery.of(context).size.width,
              // color: Colors.black,
              child: const Text(
                "Wallet Balance",
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              height: 50,
              width: MediaQuery.of(context).size.width,
              // color: Colors.black,
              child: Text(
                balance == null
                    ? "0 R2C"
                    : "${formatTokenBalance(balance)} \ R2C",
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () async {
                  await _confirmPayment();
                },
                child: const Text("Book Ticket"),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () async {
                  await _shareTokensDialog();
                },
                child: const Text("Share Tokens"),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
              ),
            ),
            Container(
                margin: const EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () {
                    credentials != null
                        ? getBalance(credentials)
                        : print("credentials null");
                    print("${balance} \R2C");
                  },
                  child: const Text("Refresh Page"),
                )),
            Container(
              margin: const EdgeInsets.only(top: 30, right: 30),
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateWallet()));
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ));
  }
}
