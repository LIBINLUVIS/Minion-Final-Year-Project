import 'package:minion/db/model/data_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';

ValueNotifier<List<StudentModel>> studentListNotifier =ValueNotifier([]);

Future<void> addStudent(StudentModel value) async{
  studentListNotifier.value.add(value);
   studentListNotifier.notifyListeners();
   final studentDB=await Hive.openBox<StudentModel>('student_db');

   print(value);
   print("hello world");
  await studentDB.add(value);
 // await studentDB.putAt(0, value);
  getAllStudents();
  if(studentDB.getAt(0)!=null){
    studentListNotifier.notifyListeners();
    print('hello');
   await studentDB.putAt(0, value);
   getAllStudents();
  }else{
    studentListNotifier.notifyListeners();
    print('hey');
   await studentDB.add(value);
   getAllStudents();
  }
}

Future<void> getAllStudents()async{
  final studentDB=await Hive.openBox<StudentModel>('student_db');
  studentListNotifier.value.clear();
  studentListNotifier.value.addAll(studentDB.values);
  studentListNotifier.notifyListeners();
 // print(studentDB.values);
 //print(studentDB.get('age'));
}

