import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('settings'); // Box for storing theme preference
  await Hive.openBox('todos'); //Open a box for storing todos
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  //const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class MyAppState extends State<MyApp> {
  final Box settingsBox = Hive.box('settings');

  @override
  Widget build(BuildContext context) {
   bool isDarkMode = settingsBox.get('darkMode', defaultValue: false);
   return ValueListenableBuilder(
       valueListenable: settingsBox.listenable(),
       builder: (context,box, child) {
         return MaterialApp(
           debugShowCheckedModeBanner: false,
           theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
           home: TodoListScreen(),
         );
       });
  }

}

class NameInputScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NameInputScreenState();
  }
}

class NameInputScreenState extends State<NameInputScreen> {
  String name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Name"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            decoration: InputDecoration(
              label: Text('Your Name'),
              border: OutlineInputBorder()
            ),
            onChanged: (text) {
              setState(() {
                name = text; // Updating the state
              });
            },
          ),
          SizedBox(height: 20),
          Text("Hello, $name!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold
            ),)
        ],
      ),
    );
  }
}

class FetchDataScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FetchDataScreenState();
  }

}

class FetchDataScreenState extends State<FetchDataScreen> {
  String data = "Fetching data...";
  Future<void> fetchData() async {
    final response = await http.get(Uri.parse("https://jsonplaceholder.typicode.com/todos/1"));
  if (response.statusCode == 200) {
    setState(() {
      data = jsonDecode(response.body)["title"];
    });
  } else {
    setState(() {
      data = "Failed to fetch data";
    });
  }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data when the screen loads
  }
  
  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text("API Fetch Example"),
     ),
     body: Center(
       child: Text(data,
         style: TextStyle(fontSize: 20,
         fontWeight: FontWeight.bold),
       textAlign: TextAlign.center),
     ),
   );
  }

}

class TodoListScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return TodoListScreenState();
  }

}

class TodoListScreenState extends State<TodoListScreen> {
  List<dynamic> todos = [];
  bool isLoading = true;
  final Box todoBox = Hive.box('todos'); // Hive storage
  final Box settingsBox = Hive.box('settings'); // Hive box for theme
  @override
  void initState() {
    super.initState();
    loadTodos();
    fetchTodos();
  }

  //Load saved todos from Hive
  void loadTodos() {
    final savedTodos =  todoBox.get('todoList', defaultValue: []);
    setState(() {
      todos = List<dynamic>.from(savedTodos);
      isLoading = false;
    });
  }

Future<void> fetchTodos() async {
    final response = await http.get(Uri.parse("https://jsonplaceholder.typicode.com/todos"));
    if (response.statusCode == 200) {
    setState(() {
      todos = jsonDecode(response.body); // Convert JSON response to List
      isLoading = false;
    });
    todoBox.put("todoList", fetchTodos); // Save to Hive
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception("Failed to load todos");
    }
  }

  //Toggle completion status of a to-do
  void toggleComplete(int index) {
    setState(() {
      todos[index]["completed"] = !todos[index]["completed"];
      todoBox.put("todoList", todos); // Update Hive storage
    });
  }
  
  // Delete a to-do from the list
  void deleteTodo(int index) {
    setState(() {
      print(index);
      todos.removeAt(index);
      todoBox.put("todoList", todos); // Update Hive storage
    });
  }
  
  //Add new To-Do
  void addTodo(String title) {
    if (title.isEmpty) return;
    setState(() {
      todos.insert(0, {"id": DateTime.now().microsecondsSinceEpoch, "title": title, "completed": false});
      todoBox.put("todoList", todos);
    });
  }

  // Edit a To-Do
  void editTodo(int index) {
    TextEditingController editingController = TextEditingController(text: todos[index]['title']);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Edit To-Do'),
            content: TextField(
            controller: editingController,
              decoration: InputDecoration(hintText: "Update task"),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel")),
              TextButton(
                  onPressed: () {
                    setState(() {
                      todos[index]["title"] = editingController.text;
                      todoBox.put("todoList", todos);
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Save"))
            ],
          );
    });
  }

  // show Add To-Do Dialog
  void showAddTodoDialog() {
    TextEditingController todoController = TextEditingController();
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("Add New To-Do"),
        content: TextField(
          controller: todoController,
          decoration: InputDecoration(hintText: "Enter task"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(onPressed: () {
              addTodo(todoController.text); // Add the todo
              todoController.clear(); // clear the TextField
              Navigator.pop(context); // Close the dialog
      }, child: Text("Add")
    )
        ],
      );
    });
  }

  //Toggle Dark Mode
  void toggleDarkMode() {
    bool isDarkMode = settingsBox.get('darkMode', defaultValue: false);
    settingsBox.put('darkMode', !isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = settingsBox.get('darkMode', defaultValue: false);
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List (Offline Mode)"),
        actions: [
          IconButton(onPressed: toggleDarkMode, icon: Icon(isDarkMode ? Icons.dark_mode: Icons.light_mode)),
          IconButton(onPressed: fetchTodos, icon: Icon(Icons.refresh))]),
      body: isLoading ?
      Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: fetchTodos,
        child: ListView.builder(itemCount: todos.length, itemBuilder: (context, index) {
          var todo = todos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(todo["title"], style: TextStyle(fontSize: 18)),
              leading: IconButton(
                icon: Icon(
                  todo["completed"] ? Icons.check_circle : Icons.circle_outlined,
                  color: todo["completed"] ? Colors.green : Colors.red,
                ),
                onPressed: () => toggleComplete(index), //Toggle Status **
              ),
              trailing: IconButton(onPressed: () => deleteTodo(index), icon: Icon(Icons.delete, color: Colors.red,)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TodoDetailScreen(todo))
                );
              },
              onLongPress: () => editTodo(index), // Long Press to edit
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(onPressed: showAddTodoDialog,
        child: Icon(Icons.add)),
    );
  }
}

class TodoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> todo;
  TodoDetailScreen(this.todo);
  @override
  Widget build(BuildContext context) {
   return Scaffold(
appBar: AppBar(
  title: Text("To-Do Details"),
),
     body: Padding(padding:
     EdgeInsets.all(16.0),
     child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         Text("To-Do ID: ${todo["id"]}",style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
         SizedBox(height: 20),
         Text(todo["title"], textAlign: TextAlign.center, style: TextStyle(fontSize: 24),),
         SizedBox(height: 20),
         Text(todo["completed"] ? "✔️ Completed" : "❌ Not Completed", style: TextStyle(fontSize: 18, color: todo["completed"] ? Colors.green : Colors.red),),
       ],
     ),
     )
   );
  }

}