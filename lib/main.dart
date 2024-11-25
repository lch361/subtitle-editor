import 'dart:io';

import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.
import 'package:file_picker/file_picker.dart';

import 'package:subtitle_editor/editor/subtitles.dart';
// import 'package:subtitle_editor/editor/time.dart';
import 'package:subtitle_editor/editor/import/srt.dart' as srt;
// import 'package:subtitle_editor/editor/export/srt.dart' as srt;
import 'package:subtitle_editor/collections/result.dart';

// Размер проигрывателя - 16 на 9
const RATIO = 9.0 / 16.0;
// Часть экрана (окна), отведённая под плеер
const playerPortion = 0.7;

// void main() {
//   // Обязательная инициализация пакета media kit
//   MediaKit.ensureInitialized();
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

void main() {
  

  WidgetsFlutterBinding.ensureInitialized();
  // Обязательная инициализации пакета media kit
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
      home: const MyHomePage(
          title:
              'Subtitle Editor Demo Home Page'), //Прямо тут можно задать новое имя, передаётся в [MyHomePage()]
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      required this.title}); //А здесь имя запрашивается, передаётся в поле [MaterialApp.home]

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
  /////////////////////////////////////////////
  // Создаём плеер и управление плейером
  // Create a [Player] to control playback.
  late Player player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late VideoController controller = VideoController(player);

  // Выбранный файл-видео
  late String? _file_video_path;
  late String? _file_sub_path;

  var subs = SubtitleTable();
  List<Subtitle> subtits = [];
  
  void getFileVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      String _videofilePath = result.files.single.path as String;
      _file_video_path = _videofilePath;
      player.open(Media(_videofilePath));
      setState(() {});
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select video file'),
      ));
    }
  }

  void getFileSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'srt'],
    );

    if (result != null) {
      _file_sub_path = result.files.single.path as String;
      print(_file_sub_path);
      build.call(context);
      setState(() {});
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select subtitle file'),
      ));
    }
  }

  ///////////////////////////////////////////////////
  // Функция для вставки видео в плейер
  @override
  void initState() {
    super.initState();
    // var subs = SubtitleTable();
    switch (SubtitleTable.import(File('test_subs/HS_StarTrekLowerDecks_s05e06_AMZN_FLUX.srt'), srt.import)) {
      case Ok(value: final v):
        subs = v;
        print("Импорт произошёл");
        for (int i = 0; i < subs.length; i++){
          setState(() { subtits.add(subs[i]);});
        }
      case Err(value: final e):
        print(e);
        print("Импорт не свершился");
      }
    // Play a [Media] or [Playlist].
    player.open(Media(
        'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
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
      appBar: AppBar(
        //Верхняя часть с именем
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        
      ),
      body: Row(
        //Тело, разделённое по колонкам
        children: [
          Column(
            children: [
              SizedBox(
                // Коробка под видео
                width: MediaQuery.sizeOf(context).width * playerPortion,
                //width: MediaQuery.of(context).size.width,
                height:
                    MediaQuery.of(context).size.width * playerPortion * RATIO,
                // Use [Video] widget to display video output.
                child: Video(controller: controller),
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.01,
              ),
              Row(
                // Для кнопок нужно разделить пространство по столбикам
                children: [
                  // Кнопка со временем
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.06,
                    height: MediaQuery.sizeOf(context).width * 0.06,
                    child: FloatingActionButton(
                      onPressed: _tellTime,
                      tooltip: 'Tells the time',
                      child: const Icon(Icons.access_time_outlined),
                    ),
                  ),

                  SizedBox(
                    width: MediaQuery.sizeOf(context).width *
                        0.02, // Помним, 0,7 отведено под плеер
                  ),

                  // Кнопка выбора видеофайла
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.06,
                    height: MediaQuery.sizeOf(context).width * 0.06,
                    child: FloatingActionButton(
                      onPressed: getFileVideo,
                      tooltip: 'Choose video file',
                      child: const Icon(Icons.video_call_rounded),
                    ),
                  ),

                  SizedBox(
                    width: MediaQuery.sizeOf(context).width *
                        0.02, // Помним, 0,7 отведено под плеер
                  ),

                  // Кнопка выбора файла субтитров
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.06,
                    height: MediaQuery.sizeOf(context).width * 0.06,
                    child: FloatingActionButton(
                      onPressed: getFileSubtitle,
                      tooltip: 'Choose subtitle file',
                      child: const Icon(Icons.text_snippet_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 5, color: Colors.black),
          Expanded(
            child: ListView.builder(
              // Построитель списка для субтитров
              itemCount: 100, //Здесь будет количество субтитров
              itemBuilder: (context, i) => ListTile(
                title: Text("${subtits[i].start.hours}:${subtits[i].start.minutes}:${subtits[i].start.seconds},${subtits[i].start.format().millisecond} - ${subtits[i].end.hours}:${subtits[i].end.minutes}:${subtits[i].end.seconds},${subtits[i].end.format().millisecond}"),
                subtitle: Text(subtits[i].text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
