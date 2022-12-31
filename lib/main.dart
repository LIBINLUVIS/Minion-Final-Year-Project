import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'mqtt_client.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minion',
      // theme: ThemeData(
      //   primarySwatch: Colors.,
      // ),
      theme: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF784CEF),
        ),
      ),
      home: const Home(title: 'Minion'),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late MqttClient client;
  var topic = "minion/childsectiondata";

  void _publish(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello from flutter_client');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload);
  }

    @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }
  bool disconnect=true;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    
    if (isBackground) {
      client.disconnect();
      if(disconnect){
      connect().then((value) {
      client = value;
      client.subscribe(topic, MqttQos.atLeastOnce);        
      });
      }
      Timer mytimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if(data=='300'){
       //   print('hello');
        }else{
       //   print('heyy you');
        }
        if(data=='500'){
        //  print('hello world ....................................................');
          Vibration.vibrate(duration: 1000);
        }

      });
      
    }
  }
  var data='';
  void alert(){
     Fluttertoast.showToast(
        msg: "connected",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void stopalert(){
      disconnect=false;
      client.unsubscribe(topic);
      client.disconnect();
      setState(() {
        data='';
      });
      Fluttertoast.showToast(
      msg: "disconnected",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    );

  }
        
  Future<MqttClient> connect() async {
    MqttServerClient client =
    MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier("flutter_client")
        .authenticateAs("test", "test")
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;
    try {
      print('Connecting');
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print('EMQX client connected');
      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

        print('Received message:$payload from topic: ${c[0].topic}>');

        //  data=payload;
        setState(() {
          data=payload;
        });

      });

      client.published.listen((MqttPublishMessage message) {
        print('published');
        final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
        print(
            'Published message: $payload to topic: ${message.variableHeader.topicName}');
      });
    } else {
      print(
          'EMQX client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }

    return client;
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe topic: $topic');
  }

  void onUnsubscribed(String topic) {
    print('Unsubscribed topic: $topic');
  }

  void pong() {
    print('Ping response client callback invoked');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children:[
            const SizedBox(height: 30,width: 20,),
            const Text("Child status",style: TextStyle(fontSize: 30,color: Color(0xFF10A19D))),
            const SizedBox(height: 20,width: 20,),
            Container(
              margin:const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    child: const Text('connect',style: TextStyle(fontSize:20),),
                    onPressed: () => {
                      connect().then((value) {
                        client = value;
                        client.subscribe(topic, MqttQos.atLeastOnce);
                        alert();
                      })
                    },
                  ),

                  ElevatedButton(
                    child: const Text('disconnect',style: TextStyle(fontSize:20),),
                    onPressed: () => {
                         stopalert()
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60,width: 30,),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:  [
                data=='300'?
                const Icon(Icons.escalator_warning,
                  color: Colors.green,
                  size: 150,
                ):const Text(''),
                data=='300'?
                const Text("Safe distance",style: TextStyle(fontSize: 20,color: Color(0xFF10A19D)),)
                :
                const Text(""),

                data=='500'?
                const Icon(Icons.escalator_warning,
                  color: Colors.red,
                  size: 150,
                ):const Text(''),
                data=='500'?
                const Text("Alert",style: TextStyle(fontSize: 20,color: Color(0xFF10A19D)),):
                const Text(""),
                data==''?
                const Text("Please click connect to view the status",
                  style: TextStyle(fontSize: 20,color: Color(0xFF10A19D)),):
                const Text('')
              ],


            ),
          ],
        ),
      ),
    );
  }
}



// HOME PAGE WIDGET

class Home extends StatefulWidget{
  const Home({super.key, required this.title});
  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{
  late MqttClient client;
  var topic = "minion/childsectiondata";
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;

    // if (isBackground) {
    //   connect().then((value) {
    //     client = value;
    //     client.unsubscribe(topic);
    //     client.disconnect();
    //   });
      
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed:(){
             Navigator.push(context, MaterialPageRoute(builder: (context)=>const
             MyHomePage(title: 'Minion') ));
            }, child: const Text("Child status",style:
            TextStyle(fontSize:20 ),)),
            const SizedBox(height: 30,width: 30,),
            ElevatedButton(onPressed:(){

            }, child: const Text("Child tracking",
            style: TextStyle(fontSize: 20 ),)),
            const SizedBox(height: 30,width: 30,),
            ElevatedButton(onPressed:(){

            }, child:const Text("Child health",style: TextStyle(fontSize: 20),))
          ],
        ),
      ),
    );
  }
}




