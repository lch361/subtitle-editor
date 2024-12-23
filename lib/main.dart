import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.
import 'package:file_picker/file_picker.dart';

import 'package:subtitle_editor/editor/subtitles.dart';
import 'package:subtitle_editor/editor/time.dart';
import 'package:subtitle_editor/editor/action_button.dart';
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
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class IncrementIntent2 extends Intent {
  const IncrementIntent2();
}

class _MyHomePageState extends State<MyHomePage> {
  // Создаём плеер и управление плейером
  late Player player = Player();
  late VideoController controller = VideoController(player);
  late SubtitleTrack subtitle = player.state.track.subtitle;
  final ScrollController _controller2 = ScrollController();

  // Выбранный файл-видео
  late String? _file_video_path;
  late String? _file_sub_path;

  var subs = SubtitleTable();
  int _selectedIndex = -1;
  List<Subtitle> saves_subs = [];
  int timeSchange = -1;
  int timeEchange = -1;
  bool selectChange = false;
  bool isDoubleTap = false;

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
      build.call(context);
      setState(() {});
      switch (
          SubtitleTable.import(File(_file_sub_path.toString()), srt.import)) {
        case Ok(value: final v):
          subs = v;
          setState(() {});
        case Err(value: final e):
          print(e);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select subtitle file'),
      ));
    }
  }

  // Функция для вставки видео в плейер
  @override
  void initState() {
    super.initState();

    // тестовый импорт вначале
    switch (SubtitleTable.import(
        File('test_subs/Star_Trek_Lower_Decks1e6.Terminal Provocations.srt'),
        srt.import)) {
      case Ok(value: final v):
        subs = v;
        setState(() {});
        _file_sub_path =
            'test_subs/Star_Trek_Lower_Decks1e6.Terminal Provocations.srt';
      case Err(value: final e):
        print(e);
    }
    // Play a [Media] or [Playlist].
    // player.open(Media(5
    //     'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
    player.open(Media('test_subs/6.Terminal Provocations.demo.mp4'),
        play: false);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _tellTime() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Video is on ${player.state.position}"),
      duration: Duration(milliseconds: 400),
    ));

    for (var i = 0; i < subs.length - 1; i++) {
      if (subs[i].start.ticks < player.state.position.inMilliseconds &&
          player.state.position.inMilliseconds < subs[i + 1].start.ticks) {
        ScrollToIndex(i, 0);
      }
    }
  }

  void ScrollToIndex(int index, double step) {
    _controller2.jumpTo(90.0 * (index + 1 + step));
  }

  void CompleteTimeStart() {
    if (timeSchange != -1) {
      int ind = subs.edit(_selectedIndex, (editor) {
        editor.start = Millis(timeSchange);
        return true;
      });
      ScrollToIndex(ind, -4);
      _selectedIndex = ind;
      timeSchange = -1;
      setState(() {});
    }
  }

  void EditTimeStart(final value) {
    DateTime tt;
    try {
      tt = DateFormat('HH:mm:ss,S').parse(value);
      int tick = tt.hour * 60 * 60 * 1000;
      tick = tick + tt.minute * 60 * 1000;
      tick = tick + tt.second * 1000;
      tick = tick + tt.millisecond;
      timeSchange = tick;
    } catch (e) {
      print(e);
    }
  }

  void CompleteTimeEnd() {
    if (timeEchange != -1) {
      int ind = subs.edit(_selectedIndex, (editor) {
        editor.end = Millis(timeEchange);
        return true;
      });
      ScrollToIndex(ind, -4);
      _selectedIndex = ind;
      timeEchange = -1;
      setState(() {});
    }
  }

  void EditTimeEnd(final value) {
    DateTime tt;
    try {
      tt = DateFormat('HH:mm:ss,S').parse(value);
      int tick = tt.hour * 60 * 60 * 1000;
      tick = tick + tt.minute * 60 * 1000;
      tick = tick + tt.second * 1000;
      tick = tick + tt.millisecond;
      timeEchange = tick;
    } catch (e) {
      print(e);
    }
  }

  void EditLine(final value, int index) {
    subs[index];
    subs.edit(index, (editor) {
      editor.text = value;
      return true;
    });
  }

  int editindex = -2;

  void setTime() {
    subs.insert(-1, (editor) {
      editor.text = "";
      editor.start = Millis(player.state.position.inMilliseconds);
      editor.end = Millis(player.state.position.inMilliseconds + 100);
      return true;
    });
    setState(() {});
  }

  void setStartTime() {
    if (editindex == -2) {
      int ind = subs.insert(-1, (editor) {
        editor.text = "";
        editor.start = Millis(player.state.position.inMilliseconds);
        editor.end = Millis(player.state.position.inMilliseconds + 100);
        return true;
      });
      editindex = ind;
    } else {
      subs.edit(editindex, (editor) {
        editor.start = Millis(player.state.position.inMilliseconds);
        return true;
      });
    }
  }

  void setEndTime() {
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
    for (var i = 0; i < subs.length - 1; i++) {
      if (subs[i].start.ticks < player.state.position.inMilliseconds &&
          player.state.position.inMilliseconds < subs[i + 1].start.ticks) {
        saves_subs.add(subs[i]);
        subs.edit(i, (_) => false);
        if (saves_subs.length == 100) {
          saves_subs.removeAt(0);
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
    if (saves_subs.length == 0) {
      return;
    }
    var s = saves_subs[saves_subs.length - 1];
    subs.insert(-1, (editor) {
      editor.text = s.text;
      editor.start = s.start;
      editor.end = s.end;
      return true;
    });
    saves_subs.removeAt(saves_subs.length - 1);
    setState(() {});
  }

  void PressedDel() {
    if (_selectedIndex == -1) {
      return;
    }
    saves_subs.add(subs[_selectedIndex]);
    subs.edit(_selectedIndex, (_) => false);
    if (saves_subs.length == 100) {
      saves_subs.removeAt(0);
    }
    setState(() {});
    _selectedIndex == -1;
  }

  void toTimeVideo() {
    Millis time = subs[_selectedIndex].start;
    player.seek(Duration(
        hours: time.format().hour,
        minutes: time.format().minute,
        seconds: time.format().second,
        milliseconds: time.format().millisecond));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(
                  LogicalKeyboardKey.keyZ, LogicalKeyboardKey.controlLeft):
              const IncrementIntent(),
          LogicalKeySet(
                  LogicalKeyboardKey.delete, LogicalKeyboardKey.shiftRight):
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
                    width: width * playerPortion,
                    height: width * playerPortion * RATIO,
                    // Use [Video] widget to display video output.
                    child: Video(controller: controller),
                  ),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.01,
                  ),
                  Row(
                    spacing: width * 0.02, // Помним, 0,7 отведено под плеер

                    // Для кнопок нужно разделить пространство по столбикам
                    children: [
                      // Кнопка со временем
                      ActionButton(
                        tooltip: 'Tells the time',
                        width: width * 0.06,
                        height: width * 0.06,
                        onPressed: _tellTime,
                        icon: Icons.access_time_outlined,
                      ),

                      // Кнопка выбора видеофайла
                      ActionButton(
                        tooltip: 'Choose video file',
                        width: width * 0.06,
                        height: width * 0.06,
                        onPressed: getFileVideo,
                        icon: Icons.video_call_rounded,
                      ),

                      // Кнопка выбора файла субтитров
                      ActionButton(
                        tooltip: 'Choose subtitle file',
                        width: width * 0.06,
                        height: width * 0.06,
                        onPressed: getFileSubtitle,
                        icon: Icons.text_snippet_rounded,
                      ),

                      // Плюс пространство между большими и маленькими кнопками
                      SizedBox(
                        width: width * 0.01,
                      ),

                      // Маленькие кнопки
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: width * 0.01,
                          children: [
                            ActionButton(
                                tooltip: "Set time",
                                height: width * 0.03,
                                width: width * 0.03,
                                onPressed: setTime,
                                icon: Icons.timer_outlined),
                            ActionButton(
                              tooltip: 'Set start-time',
                              width: width * 0.03,
                              height: width * 0.03,
                              onPressed: setStartTime,
                              icon: Icons.more_time,
                            ),
                            ActionButton(
                              tooltip: 'Set end-time',
                              width: width * 0.03,
                              height: width * 0.03,
                              onPressed: setEndTime,
                              icon: Icons.timer_rounded,
                            ),
                            ActionButton(
                              tooltip: 'Delete sub',
                              width: width * 0.03,
                              height: width * 0.03,
                              onPressed: deleteSub,
                              icon: Icons.auto_delete,
                            ),
                            ActionButton(
                              tooltip: 'Export subtitles',
                              width: width * 0.03,
                              height: width * 0.03,
                              onPressed: exportSubs,
                              icon: Icons.save_alt,
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
                    itemBuilder: (context, i) => Row(
                          children: [
                            Flexible(
                                child: ListTile(
                              onTap: () {
                                if (_selectedIndex != i) {
                                  isDoubleTap = false;
                                }
                                if (isDoubleTap) {
                                  toTimeVideo();
                                  isDoubleTap = false;
                                } else {
                                  isDoubleTap = true;
                                }
                                setState(() {
                                  _selectedIndex = i;
                                });
                              },
                              selected: i == _selectedIndex,
                              title: Row(children: [
                                SizedBox(
                                  width: width * 0.08,
                                  child: TextField(
                                    onTap: () {
                                      _selectedIndex = i;
                                    },
                                    controller: TextEditingController()
                                      ..text = DateFormat('HH:mm:ss,S').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              subs[i].start.ticks,
                                              isUtc: true)),
                                    onChanged: (value) =>
                                        {EditTimeStart(value)},
                                    onEditingComplete: () => {
                                      CompleteTimeStart(),
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                    ),
                                  ),
                                ),
                                Text(" - "),
                                SizedBox(
                                  width: width * 0.08,
                                  child: TextField(
                                    onTap: () {
                                      setState(() {
                                        _selectedIndex = i;
                                      });
                                    },
                                    controller: TextEditingController()
                                      ..text = DateFormat('HH:mm:ss,S').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              subs[i].end.ticks,
                                              isUtc: true)),
                                    onChanged: (value) => {EditTimeEnd(value)},
                                    onEditingComplete: () => {
                                      CompleteTimeEnd(),
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                    ),
                                  ),
                                ),
                              ]),
                              subtitle: TextFormField(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = i;
                                    });
                                  },
                                  controller: TextEditingController()
                                    ..text = subs[i].text,
                                  minLines: 1,
                                  maxLines: 2,
                                  onChanged: (value) => {EditLine(value, i)}),
                              onFocusChange: (value) => {
                                subs.export(File("auto.srt"), srt.export),
                                player.setSubtitleTrack(
                                    SubtitleTrack.uri("auto.srt")),
                              },
                            )),
                            SizedBox(
                              width: width * 0.03,
                              height: width * 0.03,
                              child: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      saves_subs.add(subs[i]);
                                      subs.edit(i, (_) => false);
                                      if (saves_subs.length == 100) {
                                        saves_subs.removeAt(0);
                                      }
                                    });
                                  }),
                            ),
                            SizedBox(
                                width: width * 0.008, height: width * 0.008)
                          ],
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
