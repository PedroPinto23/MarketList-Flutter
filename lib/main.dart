import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MaterialApp(
    title: 'Lista de Compras',
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addItem() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo['title'] = _toDoController.text;
      _toDoController.text = '';
      newTodo['ok'] = false;
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "LISTA DE COMPRAS",
          style: GoogleFonts.bangers(
              color: Colors.red, textStyle: TextStyle(fontSize: 30)),
        ),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Image.asset('images/bea_lista_de_compras.jpg',
                width: 449, height: 1200, fit: BoxFit.cover),
          ),
          Column(
            children: <Widget>[
              Opacity(
                opacity: 0.77,
                child: Card(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                            controller: _toDoController,
                            decoration: InputDecoration(
                                labelText: "Insira um novo Item",
                                labelStyle: GoogleFonts.permanentMarker(
                                    color: Colors.green,
                                    textStyle: TextStyle(fontSize: 18))),
                          ),
                        ),
                        RaisedButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          color: Colors.blue,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.add, color: Colors.red),
                              Text("INSERIR",
                                  style: GoogleFonts.permanentMarker(
                                      color: Colors.white,
                                      textStyle: TextStyle(fontSize: 15)))
                            ],
                          ),
                          textColor: Colors.white,
                          onPressed: _addItem,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Opacity(
      opacity: 0.85,
      child: Card(
        child: Dismissible(
            key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
            background: Container(
              color: Colors.red,
              child: Align(
                alignment: Alignment(-0.9, 0.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            direction: DismissDirection.startToEnd,
            child: CheckboxListTile(
              title: Text(_toDoList[index]['title'],
                  style: GoogleFonts.permanentMarker(
                      color: Colors.orange,
                      textStyle: TextStyle(fontSize: 25))),
              value: _toDoList[index]['ok'],
              secondary: CircleAvatar(
                child: Icon(
                  _toDoList[index]['ok'] ? Icons.check : Icons.error,
                  color: Colors.red,
                ),
              ),
              onChanged: (c) {
                setState(() {
                  _toDoList[index]['ok'] = c;
                  _saveData();
                });
              },
            ),
            onDismissed: (direction) {
              setState(() {
                _lastRemoved = Map.from(_toDoList[index]);
                _lastRemovedPos = index;
                _toDoList.removeAt(index);

                _saveData();

                final snack = SnackBar(
                  content: Text(
                      '\"Item ${_lastRemoved['title']}\" removido da lista!'),
                  action: SnackBarAction(
                      label: 'Desfazer',
                      onPressed: () {
                        setState(() {
                          _toDoList.insert(_lastRemovedPos, _lastRemoved);
                          _saveData();
                        });
                      }),
                  duration: Duration(seconds: 2),
                );
                Scaffold.of(context)
                    .removeCurrentSnackBar(); // REMOVER PILHA DE SNACKBARS(BUG)
                Scaffold.of(context).showSnackBar(snack);
              });
            }),
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
