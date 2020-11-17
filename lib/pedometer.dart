import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logic/format.dart';
import 'logic/global.dart';

class MyPedo extends StatefulWidget {
  @override
  _MyPedoState createState() => _MyPedoState();
}

class _MyPedoState extends State<MyPedo> {
  String _status = 'stopped';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      steps = event.steps;
      status.todayCount = steps - psteps;
      status.totalCount = totalsteps + steps - psteps;
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void initPlatformState() async {
    pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    stepCountStream.listen(onStepCount);

    if (!mounted) return;
  }

  void setList(int index) {
    setState(() {
      options.showList[index] = !options.showList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          accentColor: Colors.white,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            splashColor: Colors.red.withOpacity(0.25),
          )),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(height: 50),
            status.totalStatus(),
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: <Widget>[
                  SizedBox(height: 10),
                  if (options.showList[0]) status.dailyStatus(),
                  if (options.showList[1]) status.weeklyStatus(),
                  if (options.showList[2]) status.monthlyStatus(),
                  Center(
                    child: Text(
                      'Pedestrian status:',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  Icon(
                    _status == 'walking'
                        ? Icons.directions_walk
                        : _status == 'stopped'
                            ? Icons.accessibility_new
                            : Icons.error,
                    size: 100,
                    color: Colors.white,
                  ),
                  Center(
                    child: Text(
                      _status,
                      style: _status == 'walking' || _status == 'stopped'
                          ? TextStyle(fontSize: 40, color: Colors.white)
                          : TextStyle(fontSize: 40, color: Colors.red),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "btnPedo",
          onPressed: () {
            debugPrint('steps: $steps');
            debugPrint('psteps: $psteps');
            firestore
                .collection(userid)
                .doc(getdate(DateTime.now()))
                .set({'time': DateTime.now(), 'steps': steps - psteps});
            firestore
                .collection(userid)
                .doc('total_steps')
                .update({'total_steps': status.totalCount});
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
