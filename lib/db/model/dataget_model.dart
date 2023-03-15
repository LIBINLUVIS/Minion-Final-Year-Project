class Student{
  String? key;
  StudentData? studentData;

  Student({this.key,this.studentData});



}

class StudentData{
  String? latitude;
  String? longitude;

  StudentData({ this.latitude, this.longitude});
  StudentData.fromJson(Map<String,dynamic> json){
    latitude=json["latitude"];
    longitude=json["longitude"];
  }

}