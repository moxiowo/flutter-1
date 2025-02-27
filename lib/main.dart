import 'package:flutter/material.dart';
import 'dart:math';
import 'package:collection/collection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Game',
      theme: ThemeData.dark(),
      home: Game2048(),
    );
  }
}

class Game2048 extends StatefulWidget {
  @override
  _Game2048State createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  static const int gridSize = 4;
  List<List<int>> board = List.generate(gridSize, (i) => List.filled(gridSize, 0));
  int score = 0;

  @override
  void initState() {
    super.initState();
    _spawnNumber();
    _spawnNumber();
  }

  void _spawnNumber() {
    List<int> emptyCells = [];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == 0) {
          emptyCells.add(r * gridSize + c);
        }
      }
    }
    if (emptyCells.isNotEmpty) {
      int index = emptyCells[Random().nextInt(emptyCells.length)];
      board[index ~/ gridSize][index % gridSize] = Random().nextBool() ? 2 : 4;
    }
  }

  Color _getTileColor(int value) {
    if (value == 0) return Colors.grey[800]!;
    if (value == 2) return Colors.yellow[200]!;
    if (value == 4) return Colors.yellow[300]!;
    if (value == 8) return Colors.orange[300]!;
    if (value == 16) return Colors.orange[400]!;
    if (value == 32) return Colors.deepOrange[400]!;
    if (value == 64) return Colors.red[400]!;
    return Colors.red[700]!;
  }

  void _rotateBoardClockwise() {
    List<List<int>> newBoard = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        newBoard[c][gridSize - r - 1] = board[r][c];
      }
    }
    board = newBoard;
  }

  void _rotateBoardCounterClockwise() {
    List<List<int>> newBoard = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        newBoard[gridSize - c - 1][r] = board[r][c];
      }
    }
    board = newBoard;
  }

  bool _moveLeft() {
    bool moved = false;
    for (int r = 0; r < gridSize; r++) {
      List<int> row = board[r].where((val) => val != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row.removeAt(i + 1);
        }
      }
      row.addAll(List.filled(gridSize - row.length, 0));
      if (!const ListEquality().equals(board[r], row)) {
        moved = true;
        board[r] = row;
      }
    }
    return moved;
  }

  void _move(String direction) {
    bool moved = false;
    setState(() {
      if (direction == 'left') {
        moved = _moveLeft();
      } else if (direction == 'right') {
        _rotateBoardClockwise();
        _rotateBoardClockwise();
        moved = _moveLeft();
        _rotateBoardClockwise();
        _rotateBoardClockwise();
      } else if (direction == 'up') {
        _rotateBoardCounterClockwise();
        moved = _moveLeft();
        _rotateBoardClockwise();
      } else if (direction == 'down') {
        _rotateBoardClockwise();
        moved = _moveLeft();
        _rotateBoardCounterClockwise();
      }
      if (moved) {
        _spawnNumber();
        if (_isGameOver()) {
          _showGameOverDialog();
        }
      }
    });
  }

  bool _isGameOver() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == 0) return false;
        if (c < gridSize - 1 && board[r][c] == board[r][c + 1]) return false;
        if (r < gridSize - 1 && board[r][c] == board[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Game Over"),
          content: Text("Your final score is: $score"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: Text("Restart"),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      score = 0;
      board = List.generate(gridSize, (i) => List.filled(gridSize, 0));
      _spawnNumber();
      _spawnNumber();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 讓 AppBar 由 Scaffold 處理，不要放在 Column 裡
      appBar: AppBar(
        title: Text('2048 - Score: $score'),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Stack(
        children: [
          /// 背景圖片 (最底層)
          Positioned.fill(
            child: Image.asset(
              "assets/background.png",
              fit: BoxFit.cover,
            ),
          ),

          /// 主遊戲畫面 (佔滿除去 AppBar 的所有空間)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _move('up');
              } else if (details.primaryVelocity! > 0) {
                _move('down');
              }
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _move('left');
              } else if (details.primaryVelocity! > 0) {
                _move('right');
              }
            },
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                padding: EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: gridSize * gridSize,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      int value = board[index ~/ gridSize][index % gridSize];
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _getTileColor(value),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          value == 0 ? '' : '$value',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
