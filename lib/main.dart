// import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:minion/db/model/dataget_model.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'mqtt_client.dart';
import 'package:vibration/vibration.dart';
import 'package:minion/db/functions/db_functions.dart';
import 'package:minion/db/model/data_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';



Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  if(!Hive.isAdapterRegistered(StudentModelAdapter().typeId)){
  Hive.registerAdapter(StudentModelAdapter());
 }
  getAllStudents();
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
          primary:Color.fromRGBO(0,5,255,100)
        ),
      ),
      home: const Home(title: 'Minion'),
    );
  }
}

const List<String> list = <String>['One', 'Indoor Mode', 'Outdoor Mode'];
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
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
   // client.onUnsubscribed = onUnsubscribed;
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

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EMQX client connected');
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

        print('Received message:$payload from topic: ${c[0].topic}>');

        //  data=payload;
        setState(() {
          data=payload;
        });

      });



      client.published!.listen((MqttPublishMessage message) {
        print('published');
        final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

        print(
            'Published message: $payload to topic: ${message.variableHeader!.topicName}');
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
  // void getrange(String message){
  //   final builder = MqttClientPayloadBuilder();
  //   builder.addString("-40");
  //     connect().then((value) {
  //     client = value;
  //     client.publishMessage(topic1, MqttQos.atLeastOnce, builder.payload);
  //     client.subscribe(topic1, MqttQos.atLeastOnce);  
  //     });
  // }


  @override
  Widget build(BuildContext context) {

    var cardTextStyle=GoogleFonts.abel(
      fontSize: 20
    );

    return ValueListenableBuilder(valueListenable: studentListNotifier, builder: (BuildContext ctx,List<StudentModel> studentList,Widget?child){

      return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
      
        child: Column(
          children:[
            const SizedBox(height: 30,width: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Child status",style: TextStyle(fontSize: 30,color: Color(0xFF10A19D))),
                const SizedBox(height: 20,width: 10,),
                InkWell(
                 child: Icon(
                  Icons.settings
                 ),
                 onTap: (){
      //action code when clicked
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>const SettingsPage() ));
               }
                ),
           
              ],
            ),
            SizedBox(height: 30,),
            
            // data!=null?
            // Text(data.name,style: TextStyle(fontSize: 25),):
            // Text("",style: TextStyle(fontSize: 25),),
            studentList.isEmpty?
            Text(""):
            studentList[0].name=="10"||studentList[0].name=="20"||studentList[0].name=="30"?
            Text('+ ${studentList[0].name}',style: TextStyle(fontSize: 25),):
            Text(studentList[0].name,style: TextStyle(fontSize: 25),),

            const SizedBox(height: 20,width: 20,),
            Container(
              margin:const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    child: const Text('Connect',style: TextStyle(fontSize:20),),
                    onPressed: () => {
                      connect().then((value) {
                        client = value;
                        client.subscribe(topic, MqttQos.atLeastOnce);
                        alert();
                      }),
                      
                    },
                  ),

                  ElevatedButton(
                    child: const Text('Disconnect',style: TextStyle(fontSize:20),),
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


    });

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
  var topic = "minion/livelocation";
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

  var textStylebtn=GoogleFonts.abel();

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
            ElevatedButton(

              style: ElevatedButton.styleFrom(
                minimumSize: Size(50, 50),
                textStyle: GoogleFonts.orbitron()
              ),
      //   style: ElevatedButton.styleFrom(
      //   minimumSize: const Size.fromWidth(2000), // NEW
      // ),
            onPressed:(){
             Navigator.push(context, MaterialPageRoute(builder: (context)=>const
             MyHomePage(title: 'Minion') ));
            }, child: const Text("Local Tracking",style:
          TextStyle(fontSize: 20),)),
            // ElevatedButton(onPressed:(){
            //  Navigator.push(context, MaterialPageRoute(builder: (context)=>const
            //  MyHomePage(title: 'Minion') ));
            // }, child: const Text("Local Tracking",style:TextStyle(fontSize:20))


            const SizedBox(height: 30,width: 30),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                minimumSize: Size(50, 50),
                textStyle: GoogleFonts.orbitron()
              ),
            onPressed:(){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>const Health()));
            }, child: const Text("Health Monitoring",
            style: TextStyle(fontSize: 20,height: 1.5 ),)),
            const SizedBox(height: 30,width: 30,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(50, 50),
                textStyle: GoogleFonts.orbitron(),
                
              ),
            onPressed:(){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const Map()));
            }, child:const Text("Live Location",style: TextStyle(fontSize: 20,height: 1.5,letterSpacing: 3),))
          ],
        ),
      ),
    );
  }
}

// setting up the threshold value

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

String selectedoption="";

class _SettingsPageState extends State<SettingsPage> {
   
   int thre_range=0;
   void incrange(){
     setState(() {
       if(thre_range<=20){
         thre_range+=10;
       }   
     });
    }
   void decrange(){
     setState(() {
       if(thre_range>=1){
         thre_range-=10;
       }
     });
    }

   void customrangeupdate()async{
     final _student=StudentModel(name: thre_range.toString(), age: "temp");
     addStudent(_student);
     if(thre_range==0){
      Fluttertoast.showToast(
      msg: "Please select a value",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    );
     }
     if(thre_range==10){
       var k=100;   
       DatabaseReference ref1 = FirebaseDatabase.instance.ref("todos/$k");
       await ref1.update({
      "Threshold": -55,
      
    }).then((res)=>{
      Fluttertoast.showToast(
      msg: "range seted",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    }).catchError((err)=>{
      Fluttertoast.showToast(
      msg: "Error - $err",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    });
     }
     if(thre_range==20){
      var k=100;   
       DatabaseReference ref1 = FirebaseDatabase.instance.ref("todos/$k");
       await ref1.update({
      "Threshold": -65,
      
    }).then((res)=>{
      Fluttertoast.showToast(
      msg: "range seted",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    }).catchError((err)=>{
      Fluttertoast.showToast(
      msg: "Error - $err",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    });;
     }
     if(thre_range==30){
      var k=100;   
       DatabaseReference ref1 = FirebaseDatabase.instance.ref("todos/$k");
       await ref1.update({
      "Threshold": -90,
      
    }).then((res)=>{
      Fluttertoast.showToast(
      msg: "range seted",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    }).catchError((err)=>{
      Fluttertoast.showToast(
      msg: "Error - $err",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    });;
     }
   }
  
   update(res) async{
  // print(res); 
   var k=100;   
   DatabaseReference ref1 = FirebaseDatabase.instance.ref("todos/$k");
   final _student=StudentModel(name: res, age: "temp");
   addStudent(_student);
   
   if(res==""){
      Fluttertoast.showToast(
      msg: "Please select a mode",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    );
    }

   if(res=="Indoor Mode"){
    await ref1.update({
      "Threshold": -60,
      
    }).then((res)=>{
      Fluttertoast.showToast(
      msg: "Indoor selected",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    }).catchError((err)=>{
      Fluttertoast.showToast(
      msg: "Error - $err",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    });;
   }
   if(res=="Outdoor Mode"){
    await ref1.update({
      "Threshold": -80,
    }).then((res)=>{
      Fluttertoast.showToast(
      msg: "outdoor selected",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    }).catchError((err)=>{
      Fluttertoast.showToast(
      msg: "Error - $err",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0
    )
    });;
   }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minion"),
      ),

      body: Center(child: Column(
        children: [
          const SizedBox(height: 30,width:30),
          const Text("Select the mode",style: TextStyle(fontSize: 25,color: Color(0xFF10A19D)),),
          SizedBox(height: 120,width:40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonExample(),
              ElevatedButton(onPressed: (){
                update(selectedoption);
              }, child:Text("save",style: TextStyle(color:Color.fromARGB(255, 230, 236, 237),fontSize: 20 ),))
            ],
          ),
          SizedBox(height: 110,width:20),
          Text("Custom range",style: TextStyle(fontSize: 25,color:Color(0xFF10A19D)),),
          SizedBox(height: 50,width: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                InkWell(
                 child: Icon(
                  Icons.add_sharp
                 ),
                 onTap: (){
  
                  incrange();
               }
                ),
              SizedBox(height: 0,width: 30,),
              Text(thre_range.toString(),style: TextStyle(fontSize: 35),),
              SizedBox(height: 0,width: 30,),
              InkWell(
                 child: Icon(
                  Icons.minimize_sharp
                 ),
                 onTap: (){
      //action code when clicked
                  decrange();
               }
                )
            ],
          ),
         SizedBox(height: 30,),
         SizedBox(
          height: 30,
          width: 150,
          child: ElevatedButton(onPressed: (){
            customrangeupdate();
          }, child:Text("save",style: TextStyle(fontSize: 20),))
         ),
         
        ],
      ),

      ),

    );
  }
}





//dropdown widget
class DropdownButtonExample extends StatefulWidget {
  
  const DropdownButtonExample({super.key});
   

  @override
  State<DropdownButtonExample> createState() => _DropdownButtonExampleState();
  
}

class _DropdownButtonExampleState extends State<DropdownButtonExample> {
  
  String dropdownValue = list.first;
  
  
  

  @override
  Widget build(BuildContext context) {
   return ValueListenableBuilder(valueListenable: studentListNotifier, builder: (BuildContext ctx,List<StudentModel> studentList,Widget?child){
       return DropdownButton<String>(
       value: dropdownValue,
      
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
          selectedoption=dropdownValue;
        });
      },
      items: list.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
   });

  }

}

 class Map extends StatefulWidget {
  const Map({super.key});
  
  @override
  State<Map> createState() => _MapState();
}


class _MapState extends State<Map> {  


 Future<void> googlemap() async{ 

String latval="0.0";
String longval="0.0";
final ref = FirebaseDatabase.instance.ref();
final lat = await ref.child('temp/latitude').get();
final long=await ref.child('temp/longitude').get();
if (lat.exists && long.exists) {
   latval=lat.value.toString();
   longval=long.value.toString();

} else {
    print('No data available.');
}
  
  final Uri _url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latval,$longval');

  //String gmapurl='https://www.google.com/maps/search/?api=1&query=$latval,$longval';
   if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
  //await canLaunchUrlString(gmapurl)?launchUrlString(gmapurl):throw 'Could not open map';
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minion"),
      ),
      body: Center(child: Column(
        
        children: [
          SizedBox(height: 30,),
          Text("Google Map Location",style: TextStyle(fontSize: 25),),
          SizedBox(height: 50,),
          ElevatedButton(onPressed: (){
          googlemap();
          }, child: Text("Open google map"))
          ],
      ),),
    );
  }
}

// health widget
class Health extends StatefulWidget {
  const Health({super.key});

  @override
  State<Health> createState() => _HealthState();
  
}

class _HealthState extends State<Health> with WidgetsBindingObserver,SingleTickerProviderStateMixin{
  late Animation<double> animation;
  late AnimationController controller;
  

  @override
  initState() {
    super.initState();
 
    final quick = const Duration(milliseconds: 500);
    final scaleTween = Tween(begin: 0.0, end: 1.0);
    controller = AnimationController(duration: quick, vsync: this);
    animation = scaleTween.animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    )..addListener(() {
      
      setState(() => scale = animation.value);
    });

        Timer mytimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
       
       _animate();
      });
    WidgetsBinding.instance.addObserver(this);
    gethealthdata();

  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    
    if(isBackground){
     
      gethealthdata();
      Timer mytimer = Timer.periodic(Duration(seconds: 5), (timer) {
        if(abnormal_heartrate && water_detected){
          Vibration.vibrate(duration: 1000);
        }

      });
    }

   



  }

  String heart_rate_value="0";
  bool water_detected=false;
  bool child_drowns=false;
  bool abnormal_heartrate=false;
  var arr=[0];

  void emptyarray(){
    
    setState(() {
      arr[0]=0;
      abnormal_heartrate=false;
    });
  }

    void _animate() {
    animation
    ..addStatusListener((AnimationStatus status) {
      if (scale == 1.0) {
        controller.reverse();
      } 
    });
    controller.forward();
  }

  void gethealthdata(){
    
    final ref = FirebaseDatabase.instance.ref();
    ref.child('test').child('health').onValue.listen((event) {

     String data=event.snapshot.value.toString();
   
     setState(() {
       heart_rate_value=data;
     });
    //logic
    if(arr!=null && arr[0]!=0){
      int val_diff=arr[0]-int.parse(heart_rate_value);
      print(val_diff);
     if(val_diff<=-10){
      
      setState(() {
        abnormal_heartrate=true;
      });
     
     }else{
      arr[0]=int.parse(heart_rate_value);
     }
    }else{ 
      arr[0]=int.parse(heart_rate_value);
    }

    });

    ref.child('water').child('statusCode').onValue.listen((event) {
      String data=event.snapshot.value.toString();
      if(data=="600"){
        setState(() {
          water_detected=true;
        });
      }
    });
    
  }
  double scale = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minion"),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                SizedBox(height: 300,),
                Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.red,
                  ),
                ),
               SizedBox(width: 15,),
               abnormal_heartrate && water_detected?
               Text(heart_rate_value,style:TextStyle(fontSize: 45,color: Colors.red)):
               Text(heart_rate_value,style:TextStyle(fontSize: 45,color: Colors.green)),
              ],
              
            ),
              Icon(
               Icons.child_care_rounded,
               size: 54.0,
              ),
              SizedBox(height: 20,),
              abnormal_heartrate && water_detected?
              
              Column(
                children: [
                  Text('Child drowning detected',style: TextStyle(fontSize: 30,color: Colors.red)),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    primary: Colors.red
                
              ),
                    onPressed: ()=>{
                      emptyarray()
                  }, child: Text('Cancel',style:TextStyle(fontSize: 15,color: Colors.white)))
                ],
              )
              :
              Text('Child is Safe',style: TextStyle(fontSize: 30,color: Colors.green),)
          ],
        ),
      ),
    );
  }
}


