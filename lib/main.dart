import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.
import 'package:file_picker/file_picker.dart';

import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:subtitle_editor/editor/time.dart';
import 'package:subtitle_editor/editor/import/srt.dart' as srt;
import 'package:subtitle_editor/editor/export/srt.dart' as srt;
import 'package:subtitle_editor/collections/result.dart';

// Размер проигрывателя - 16 на 9
const RATIO = 9.0 / 16.0;
// Часть экрана (окна), отведённая под плеер
const playerPortion = 0.7;

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

class IncrementIntent extends Intent {
    const IncrementIntent();}

class IncrementIntent2 extends Intent {
    const IncrementIntent2();}

class _MyHomePageState extends State<MyHomePage> {
  /////////////////////////////////////////////
  // Создаём плеер и управление плейером
  // Create a [Player] to control playback.
  late Player player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late VideoController controller = VideoController(player);
  late SubtitleTrack subtitle = player.state.track.subtitle;


  final ScrollController _controller2 = ScrollController();
 

  // Выбранный файл-видео
  late String? _file_video_path;
  late String? _file_sub_path;

  var subs = SubtitleTable();
  int _selectedIndex = -1;
  List<Subtitle> saves_subs = [];

  // импорт видео в программу
  void getFileVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      String _videofilePath = result.files.single.path as String;
      _file_video_path = _videofilePath;
      player.open(Media(_videofilePath));
      player.setSubtitleTrack(SubtitleTrack.uri("auto.srt"));
      setState(() {});
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select video file'),
      ));
    }
  }

  // импорт субтитров в таблицу
  void getFileSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'srt'],
    );

    if (result != null) {
      _file_sub_path = result.files.single.path as String;
      player.setSubtitleTrack(SubtitleTrack.uri(_file_sub_path.toString()));
      subs.export(File("auto.srt"), srt.export);
      saves_subs.clear();

      setState(() {});
      print(_file_sub_path);
      build.call(context);
      setState(() {});
      switch (SubtitleTable.import(File(_file_sub_path.toString()), srt.import)) {
        case Ok(value: final v):
          subs = v;
          print(subs[0].text);
          setState(() { });
          print("Файл субтитров загрузился");
        case Err(value: final e):
          print(e);
          print("Ошибка при загрузке файла - возможно, не тот тип файла");
        }
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
    
    // тестовый импорт вначале
    switch (SubtitleTable.import(File('test_subs/HS_StarTrekLowerDecks_s05e06_AMZN_FLUX.srt'), srt.import)) {
      case Ok(value: final v):
        subs = v;
        setState(() { });
        print("Файл субтитров прошёл");
        _file_sub_path = 'test_subs/HS_StarTrekLowerDecks_s05e06_AMZN_FLUX.srt';
      case Err(value: final e):
        print(e);
        print("Ошибка импорта субтитров");
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
      duration: Duration(milliseconds: 400,),
    ));
    print(_controller2);
    for (var i = 0; i < subs.length - 1; i++) {
      if (subs[i].start.ticks < player.state.position.inMilliseconds && player.state.position.inMilliseconds < subs[i + 1].start.ticks) {
        print("ОН ТУТ ВИДЕТ");
        _controller2.jumpTo(90.0 * (i + 1));
      }
    }
  }

   void EditTimeStart(final value, int index) {
    DateTime tt;
    try {
      tt = DateFormat('HH:mm:ss,S').parse(value);
      int tick = tt.hour * 60 * 60 * 1000;
      tick = tick + tt.minute * 60 * 1000;
      tick = tick + tt.second * 1000;
      tick = tick + tt.millisecond;
      print(tick);
      print("-=-= Отредактирован time =-=-");
      subs.edit(index, (editor) {
        editor.start = Millis(tick);
        return true;
      });
    } catch (e) {
      print("ВРЕМЯ НЕ ТО");
    }
  }

   void EditTimeEnd(final value, int index) {
    DateTime tt;
    try {
      tt = DateFormat('HH:mm:ss,S').parse(value);
      int tick = tt.hour * 60 * 60 * 1000;
      tick = tick + tt.minute * 60 * 1000;
      tick = tick + tt.second * 1000;
      tick = tick + tt.millisecond;
      print(tick);
      print("-=-= Отредактирован time =-=-");
      subs.edit(index, (editor) {
        editor.end = Millis(tick);
        return true;
      });
    } catch (e) {
      print("ВРЕМЯ НЕ ТО 2");
    }
  }

  void EditLine(final value, int index) {
    subs[index];
    print("-=-= Отредактирован =-=-");
    subs.edit(index, (editor) {
      editor.text = value;
      return true;
    });
    print(subs[index].text);
  }

  int editindex = -2;

  void setTime() {
    print("posis start: ${player.state.position}");
    int ind = subs.insert(-1, (editor) {
        editor.text = "";
        editor.start = Millis(player.state.position.inMilliseconds);
        editor.end = Millis(player.state.position.inMilliseconds + 100);
        return true;
    });
    print(ind);
    setState(() {});
  }

  void setStartTime() {
    print("start: ${player.state.position}");
    if (editindex == -2) {
    int ind = subs.insert(-1, (editor) {
        editor.text = "";
        editor.start = Millis(player.state.position.inMilliseconds);
        editor.end = Millis(player.state.position.inMilliseconds + 100);
        return true;
    });
    editindex = ind;
    print(ind);
    }
    else {
      subs.edit(editindex, (editor) {
        editor.start = Millis(player.state.position.inMilliseconds);
        return true;
    });
    }
  }

  void setEndTime() {
    print("end: ${player.state.position}");
    if (editindex != -2) {
    subs.edit(editindex, (editor) {
        editor.end = Millis(player.state.position.inMilliseconds);
        return true;
    });
    setState(() {});
    }
    editindex = -2;
  }
  void deleteSub() {
    print(_controller2);
    for (var i = 0; i < subs.length - 1; i++) {
      if (subs[i].start.ticks < player.state.position.inMilliseconds && player.state.position.inMilliseconds < subs[i + 1].start.ticks) {
        saves_subs.add(subs[i]);
        subs.edit(i, (_) => false);
        while (saves_subs.length > 100) {
          print("УДАЛЕННО:");
          print(saves_subs.removeAt(0).text);
        }
        setState(() {});
      }
    }
  }

  void exportSubs() async {
  final result = await FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: ['txt', 'srt'],
  );
  
  subs.export(File(result.toString()), srt.export);
  }
  
  void PressedCtrlZ() {
    print("PRESS Z");
    if (saves_subs.length == 0) {return;}
    var s = saves_subs[saves_subs.length - 1];
    int ind = subs.insert(-1, (editor) {
        editor.text = s.text;
        editor.start = s.start;
        editor.end = s.end;
        return true;
    });
    saves_subs.removeAt(saves_subs.length - 1);
    setState(() {});
  }

  void PressedDel() {
    print("PRESS DELshift");
    if (_selectedIndex == -1) {return;}

    saves_subs.add(subs[_selectedIndex]);
    subs.edit(_selectedIndex, (_) => false);
    while (saves_subs.length > 100) {
      print("УДАЛЕННО:");
      print(saves_subs.removeAt(0).text);
    }
    setState(() {});
    _selectedIndex == -1;
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
    body: Shortcuts( 
      shortcuts: <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.keyZ, LogicalKeyboardKey.controlLeft):
          const IncrementIntent(),
      LogicalKeySet(LogicalKeyboardKey.delete, LogicalKeyboardKey.shiftRight):
        const IncrementIntent2(),
    },
    child: Actions(
      actions: <Type, Action<Intent>>{
        IncrementIntent: CallbackAction<IncrementIntent>(
          onInvoke: (IncrementIntent intent) => PressedCtrlZ(),
        ),
        IncrementIntent2: CallbackAction<IncrementIntent2>(
          onInvoke: (IncrementIntent2 intent) => PressedDel(),
        ),
      },
      child: Row(
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
                child: Video(controller: controller,
                ),
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
                  SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.05,
                      height: MediaQuery.sizeOf(context).width * 0.05,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.03,
                      height: MediaQuery.sizeOf(context).width * 0.03,
                      
                      child: FloatingActionButton(
                        onPressed: setTime,
                        tooltip: 'Set time',
                        child: const Icon(Icons.timer_outlined),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.01,
                      height: MediaQuery.sizeOf(context).width * 0.01,),
                      SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.03,
                      height: MediaQuery.sizeOf(context).width * 0.03,
                      
                      child: FloatingActionButton(
                        onPressed: setStartTime,
                        tooltip: 'Set start-time',
                        child: const Icon(Icons.more_time),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.01,
                      height: MediaQuery.sizeOf(context).width * 0.01,),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.03,
                      height: MediaQuery.sizeOf(context).width * 0.03,
                      child: FloatingActionButton(
                        onPressed: setEndTime,
                        tooltip: 'Set end-time',
                        child: const Icon(Icons.timer_rounded),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.01,
                      height: MediaQuery.sizeOf(context).width * 0.01,),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.03,
                      height: MediaQuery.sizeOf(context).width * 0.03,
                      child: FloatingActionButton(
                        onPressed: deleteSub,
                        tooltip: 'Delete sub',
                        child: const Icon(Icons.auto_delete),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.01,
                      height: MediaQuery.sizeOf(context).width * 0.01,),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.03,
                      height: MediaQuery.sizeOf(context).width * 0.03,
                      child: FloatingActionButton(
                        onPressed: exportSubs,
                        tooltip: 'Export subtitles',
                        child: const Icon(Icons.save_alt),
                      ),
                    ),
                  ]),
                  
                ],
              ),
            ],
          ),
          Container(width: 5, color: Colors.black),
          Expanded(
            child: ListView.builder(
              // Построитель списка для субтитров
              controller: _controller2,
              itemCount: subs.length, // количество субтитров
              itemBuilder: (context, i) => 
              Row(
              children: [Flexible(
                child: ListTile(
                onTap: () {setState(() {_selectedIndex = i; print(i);});},
                selected: i == _selectedIndex,
                title: Row(
                  children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.08,
                    child: TextField(
                      onTap: () {setState(() {_selectedIndex = i; print(i);});},
                      controller: TextEditingController()..text = "${DateFormat('HH:mm:ss,S').format(DateTime.fromMillisecondsSinceEpoch(subs[i].start.ticks, isUtc:true))}",
                      onChanged: (value) => {EditTimeStart(value, i)},
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        ),
                        ),
                      ),
                  Text(" - "),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.08,
                    child: TextField(
                      onTap: () {setState(() {_selectedIndex = i; print(i);});},
                      controller: TextEditingController()..text = "${DateFormat('HH:mm:ss,S').format(DateTime.fromMillisecondsSinceEpoch(subs[i].end.ticks, isUtc:true))}",
                      onChanged: (value) => {EditTimeEnd(value, i)},
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        ),
                        ),
                  ),
                ]
                ),
                
                subtitle: TextFormField(
                  onTap: () {setState(() {_selectedIndex = i; print(i);});},
                  controller: TextEditingController()..text = subs[i].text,
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (value) => {EditLine(value, i)}),
                  onFocusChange: (value) => {print("+++= На фокусе =+++"),
                    subs.export(File("auto.srt"), srt.export),
                    player.setSubtitleTrack(SubtitleTrack.uri("auto.srt")),
                    print("автосохранение субтитров"),
                    },
              )),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.03,
                height: MediaQuery.sizeOf(context).width * 0.03,
                child:   IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      saves_subs.add(subs[i]);
                      subs.edit(i, (_) => false);
                      print(saves_subs[saves_subs.length - 1].text);
                      while (saves_subs.length > 100) {
                        print("УДАЛЕННО:");
                        print(saves_subs.removeAt(0).text);
                      }
                    });
                  }),),
                  
                  SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.008,
                height: MediaQuery.sizeOf(context).width * 0.008)],)
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
