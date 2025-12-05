
import 'package:first_flutter/data/classes/post_class.dart';
import 'package:first_flutter/views/widgets/hero_widget.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  @override
  void initState() {
    getData();
    super.initState();
  }

  Future getData() async {
    var url = Uri.parse('https://jsonplaceholder.typicode.com/todos/1');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load Post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              widget = CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              Post post = snapshot.data;
              widget = Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    HeroWidget(title: 'Course'),
                    SizedBox(height: 10.0),
                    ExpansionTile(
                      title: const Text('Dart Programming'),
                      children: <Widget>[
                        ListTile(title: Text('Class'), trailing: Text('20')),
                        ListTile(
                          title: Text('Price'),
                          trailing: Text('1.000.000 VND'),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: Text('API Title: ${post.title}'),
                      children: <Widget>[
                        ListTile(title: Text('Class'), trailing: Text('20')),
                        ListTile(
                          title: Text('Price'),
                          trailing: Text('3.000.000 VND'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              widget = Center(child: Text('Error'));
            }
            return widget;
          },
        ),
      ),
    );
  }
}
