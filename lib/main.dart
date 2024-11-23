import 'dart:io';

import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';                      // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';          // Provides [VideoController] & [Video] etc.
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Обязательная инициализация пакета media kit
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subtitle editor',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Subtitle Editor Demo Home Page'), //Прямо тут можно задать новое имя, передаётся в [MyHomePage()]
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title}); //А здесь имя запрашивается, передаётся в поле [MaterialApp.home]

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  /////////////////////////////////////////////
  // Создаём плеер и управление плейером
  // Create a [Player] to control playback.
  late Player player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late VideoController controller = VideoController(player);

  // Выбранный файл-видео
  late File? _file_video;
  late File? _file_sub;

  void getFileVideo() async {
   FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.video,
    //allowedExtensions: ['mp4', 'mov', 'avi', 'wmv'],
   );
 
   if (result != null) {
    String _videofilePath = result.files.single.path!;
    print(_videofilePath);
    player.open(Media(_videofilePath));
    setState(() {});
   } else {
     // User canceled the picker
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
       content: Text('Файл не выбран'),
     ));
   }
 }

 void getFileSubtitle() async {
   FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['txt', 'srt'],
   );
 
   if (result != null) {
    _file_sub = File(result.files.single.path!);
    setState(() {});
   } else {
     // User canceled the picker
     // You can show snackbar or fluttertoast
     // here like this to show warning to user
     // ignore: use_build_context_synchronously
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
       content: Text('Please select file'),
     ));
   }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  ///////////////////////////////////////////////////
  // Функция для вставки видео в плейер
  @override
  void initState() {
    super.initState();
    // Play a [Media] or [Playlist].
    player.open(Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _tellTime() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text("Video is on ${player.state.position}"),
     ));
    //print(player.state.position);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar( //Верхняя часть с именем
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Row( //Тело, разделённое по колонкам
        children: [
        
        Column(children: [
          
          SizedBox( // Коробка под видео
            width: MediaQuery.sizeOf(context).width * 0.7,
            //width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 0.7 * RATIO,
            // Use [Video] widget to display video output.
            child: Video(controller: controller),
          ),

          Row( // Для кнопок нужно разделить пространство по столбикам
            children: [

              SizedBox(
                width: 120,
                height: 120,
                child: FloatingActionButton(
                  onPressed: _tellTime,
                  tooltip: 'Tells the time',
                  child: const Icon(Icons.access_time_outlined),
                ),
              ),

              SizedBox(
                width: 120,
                height: 120,
                child: FloatingActionButton(
                  onPressed: getFileVideo,
                  tooltip: 'Choose video file',
                  child: const Icon(Icons.video_call_rounded),
                ),
              ),

              SizedBox(
                width: 120,
                height: 120,
                child: FloatingActionButton(
                  onPressed: getFileSubtitle,
                  tooltip: 'Choose subtitle file',
                  child: const Icon(Icons.text_snippet_rounded),
                ),
              ),

            ],
            
          ),

        ],),


        Container(width: 5, color: Colors.black),
        Expanded(
          child: ListView.builder( //Субтитры
            itemCount: 10, //Здесь будет количество субтитров
            itemBuilder: (context, i) => ListTile(
            title: Text('0:00:05 - 00:10:20'),
            subtitle: Text('Ты спас меня, теперь я должен тебе'),
            ),
          ),
        ),
      ],
      ),
    );
    
    /*return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:
      Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );*/
  }
}
