// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: MyApp()));
}

/// ==== CONFIG ====
const String BASE_URL = "http://localhost:8000"; 


final storage = FlutterSecureStorage();

/// ==== APP STATE ====
class AppState extends ChangeNotifier {
  String? _token;
  String? _email;
  String? _role;

  String? get token => _token;
  String? get email => _email;
  String? get role => _role;

  bool get isLoggedIn => _token != null;

  Future<void> loadFromStorage() async {
    _token = await storage.read(key: "access_token");
    _email = await storage.read(key: "email");
    _role = await storage.read(key: "role");
    notifyListeners();
  }

  Future<void> saveToken(String token, String email, String role) async {
    _token = token;
    _email = email;
    _role = role;
    await storage.write(key: "access_token", value: token);
    await storage.write(key: "email", value: email);
    await storage.write(key: "role", value: role);
    notifyListeners();
  }

  Future<void> logout() async {
    // call backend logout (optional)
    if (_token != null) {
      try {
        final res = await http.post(
          Uri.parse("$BASE_URL/auth/logout"),
          headers: {"Authorization": "Bearer $_token"},
        );
        // ignore response result
      } catch (_) {}
    }
    _token = null;
    _email = null;
    _role = null;
    await storage.deleteAll();
    notifyListeners();
  }
}

/// ==== UTIL ====
Map<String, String> authHeaders(String? token) {
  final h = {"Content-Type": "application/json"};
  if (token != null) h["Authorization"] = "Bearer $token";
  return h;
}

/// ==== APP ====
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // load token on app start
    Provider.of<AppState>(context, listen: false).loadFromStorage();
    return MaterialApp(
      title: 'Traffic Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Consumer<AppState>(builder: (c, s, _) {
        if (!s.isLoggedIn) return AuthPage();
        return HomePage();
      }),
    );
  }
}



/// ==== AUTH PAGE: login / register send-code / confirm ====
class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passwordCtl = TextEditingController();
  final TextEditingController _codeCtl = TextEditingController();

  bool loading = false;
  String message = "";

  // ================= LOGIN ==================
  Future<void> login() async {
    setState(() {
      loading = true;
      message = "";
    });

    try {
      final res = await http.post(
        Uri.parse("$BASE_URL/auth/token"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": _emailCtl.text.trim(),
          "password": _passwordCtl.text
        },
      );

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final token = j["access_token"];

        final meRes = await http.get(
          Uri.parse("$BASE_URL/api/users/me"),
          headers: authHeaders(token),
        );

        if (meRes.statusCode == 200) {
          final me = jsonDecode(meRes.body);
          final role = me["role"] ?? "viewer";

          await Provider.of<AppState>(context, listen: false)
              .saveToken(token, me["email"], role);
        } else {
          message = "Login succeeded but failed to fetch profile.";
        }
      } else {
        message = "Login failed: ${res.statusCode} ${res.body}";
      }
    } catch (e) {
      message = "Error: $e";
    }

    setState(() => loading = false);
  }

  // ============= SEND REGISTER CODE ================
  Future<void> sendRegisterCode() async {
    final email = _emailCtl.text.trim();

    print("DEBUG SEND CODE — email='$email'");

    if (email.isEmpty) {
      setState(() => message = "Email cannot be empty");
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    try {
      final res = await http.post(
        Uri.parse("$BASE_URL/auth/register/send-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (res.statusCode == 200) {
        message = "Verification code sent to email.";
      } else {
        message = "Failed: ${res.statusCode} ${res.body}";
      }
    } catch (e) {
      message = "Error: $e";
    }

    setState(() => loading = false);
  }

  // ============= CONFIRM REGISTER ================
  Future<void> confirmRegister() async {
    final email = _emailCtl.text.trim();
    final code = _codeCtl.text.trim();
    final password = _passwordCtl.text;

    print("DEBUG CONFIRM — email='$email', code='$code'");

    if (email.isEmpty || code.isEmpty || password.isEmpty) {
      setState(() => message = "Fill in all fields.");
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    try {
      final res = await http.post(
        Uri.parse("$BASE_URL/auth/register/confirm"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "code": code,
          "password": password,
        }),
      );

      if (res.statusCode == 200) {
        message = "Registered successfully. Please login.";
      } else {
        message = "Register confirm failed: ${res.statusCode} ${res.body}";
      }
    } catch (e) {
      message = "Error: $e";
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _codeCtl.dispose();
    super.dispose();
  }

  // =============== UI BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Traffic Manager - Login / Register")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: ValueKey("email_field"),
              controller: _emailCtl,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: 8),

            TextField(
              controller: _passwordCtl,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: loading ? null : login,
              icon: Icon(Icons.login),
              label: Text("Login"),
            ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),

            Text("Register (2-step): Send code → Confirm"),
            SizedBox(height: 8),

            TextField(
              controller: _codeCtl,
              decoration: InputDecoration(labelText: "Verification code"),
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print("Pressed SEND CODE, email = '${_emailCtl.text}");
                      sendRegisterCode();
                    },
                    child: Text("Send code"),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print("Pressed CONFIRM REGISTER");
                      confirmRegister();
                    },
                    child: Text("Confirm register"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            if (loading) CircularProgressIndicator(),

            if (message.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ==== HOME PAGE with tabs ====
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum TabItem { dashboard, lights, alerts, users, profile }

class _HomePageState extends State<HomePage> {
  TabItem current = TabItem.dashboard;

  Widget _bodyFor(TabItem t) {
    switch (t) {
      case TabItem.dashboard:
        return DashboardTab();
      case TabItem.lights:
        return LightsTab();
      case TabItem.alerts:
        return AlertsTab();
      case TabItem.users:
        return UsersTab();
      case TabItem.profile:
        return ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Traffic Manager (${state.email ?? 'user'}) - ${state.role ?? ''}"),
        actions: [
          IconButton(
              onPressed: () => Provider.of<AppState>(context, listen: false).logout(),
              icon: Icon(Icons.logout))
        ],
      ),
      body: _bodyFor(current),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: TabItem.values.indexOf(current),
        onTap: (i) => setState(() => current = TabItem.values[i]),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.traffic), label: "Lights"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// ==== Dashboard Tab: recent traffic + query stats ====
class DashboardTab extends StatefulWidget {
  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<dynamic> rows = [];
  bool loading = false;
  String msg = "";

  Future<void> fetchRecent() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/traffic/recent?limit=50"),
          headers: authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          rows = data;
        });
      } else {
        setState(() {
          msg = "Failed: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchStats() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final to = DateTime.now().toUtc();
      final from = to.subtract(Duration(hours: 1));
      final res = await http.get(Uri.parse(
          "$BASE_URL/api/traffic/stats?from_ts=${Uri.encodeComponent(from.toIso8601String())}&to_ts=${Uri.encodeComponent(to.toIso8601String())}&interval=minute"),
          headers: authHeaders(token));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        // show alert with series length
        final series = j["series"] as List;
        setState(() {
          msg = "Stats loaded: ${series.length} points (last 1h)";
        });
      } else {
        setState(() {
          msg = "Stats failed: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecent();
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('yyyy-MM-dd HH:mm:ss');

    return RefreshIndicator(
      onRefresh: fetchRecent,
      child: ListView(
        padding: EdgeInsets.all(12),
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                  onPressed: loading ? null : fetchRecent,
                  icon: Icon(Icons.refresh),
                  label: Text("Refresh")),
              SizedBox(width: 8),
              ElevatedButton.icon(
                  onPressed: loading ? null : fetchStats,
                  icon: Icon(Icons.show_chart),
                  label: Text("Get stats (last 1h)")),
            ],
          ),
          SizedBox(height: 12),
          if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.green)),
          SizedBox(height: 12),
          Text("Recent traffic (latest first):", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          if (loading) Center(child: CircularProgressIndicator()),
          ...rows.map((r) {
            final ts = r["timestamp"] ?? r["timestamp"];
            final parsed = ts != null ? DateTime.tryParse(ts)?.toLocal() : null;
            final tsStr = parsed != null ? f.format(parsed) : ts?.toString() ?? "";
            final meta = r["meta"];
            return Card(
              child: ListTile(
                title: Text("${r["camera_id"] ?? 'unknown'}  — ${r["count"]}"),
                subtitle: Text("time: $tsStr\nmeta: ${meta ?? '-'}"),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// ==== Lights Tab ====
class LightsTab extends StatefulWidget {
  @override
  _LightsTabState createState() => _LightsTabState();
}

class _LightsTabState extends State<LightsTab> {
  List<dynamic> lights = [];
  bool loading = false;
  String msg = "";

  final _intersectionCtl = TextEditingController();
  final _redCtl = TextEditingController(text: "10");
  final _yellowCtl = TextEditingController(text: "3");
  final _greenCtl = TextEditingController(text: "12");

  Future<void> fetchLights() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/lights"), headers: authHeaders(token));
      if (res.statusCode == 200) {
        setState(() {
          lights = jsonDecode(res.body);
        });
      } else {
        setState(() {
          msg = "Failed to fetch lights: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> setLight() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final body = {
        "intersection": _intersectionCtl.text.trim(),
        "red": int.tryParse(_redCtl.text) ?? 10,
        "yellow": int.tryParse(_yellowCtl.text) ?? 3,
        "green": int.tryParse(_greenCtl.text) ?? 12
      };
      final res = await http.post(Uri.parse("$BASE_URL/api/lights"),
          headers: authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        msg = "Light set ok";
        await fetchLights();
      } else {
        msg = "Failed to set: ${res.statusCode} ${res.body}";
      }
    } catch (e) {
      msg = "Error: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLights();
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AppState>(context).role ?? "viewer";
    final canControl = role == "admin" || role == "police";
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        Text("Lights (intersection settings) - role: $role"),
        SizedBox(height: 8),
        Row(children: [
          ElevatedButton(onPressed: loading ? null : fetchLights, child: Text("Refresh")),
          SizedBox(width: 8),
          if (!canControl) Text("You need admin/police to modify", style: TextStyle(color: Colors.red))
        ]),
        SizedBox(height: 12),
        if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.green)),
        ...lights.map((l) {
          return Card(
            child: ListTile(
              title: Text("${l["intersection"]}"),
              subtitle: Text("R:${l["red"]} Y:${l["yellow"]} G:${l["green"]}\nUpdated: ${l["updated_at"] ?? '-'}"),
            ),
          );
        }).toList(),
        Divider(),
        Text("Set / Update light (admin/police)"),
        TextField(controller: _intersectionCtl, decoration: InputDecoration(labelText: "Intersection")),
        Row(children: [
          Flexible(child: TextField(controller: _redCtl, decoration: InputDecoration(labelText: "Red (s)"))),
          SizedBox(width: 8),
          Flexible(child: TextField(controller: _yellowCtl, decoration: InputDecoration(labelText: "Yellow (s)"))),
          SizedBox(width: 8),
          Flexible(child: TextField(controller: _greenCtl, decoration: InputDecoration(labelText: "Green (s)"))),
        ]),
        SizedBox(height: 8),
        ElevatedButton(onPressed: canControl ? setLight : null, child: Text("Set Light")),
      ],
    );
  }
}

/// ==== Alerts Tab ====
class AlertsTab extends StatefulWidget {
  @override
  _AlertsTabState createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  List<dynamic> alerts = [];
  bool loading = false;
  String msg = "";

  Future<void> fetchAlerts() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/alerts?limit=50"), headers: authHeaders(token));
      if (res.statusCode == 200) {
        setState(() {
          alerts = jsonDecode(res.body);
        });
      } else {
        setState(() {
          msg = "Failed: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('yyyy-MM-dd HH:mm:ss');
    return RefreshIndicator(
      onRefresh: fetchAlerts,
      child: ListView(
        padding: EdgeInsets.all(12),
        children: [
          ElevatedButton(onPressed: fetchAlerts, child: Text("Refresh alerts")),
          if (msg.isNotEmpty) Text(msg),
          ...alerts.map((a) {
            final ts = a["timestamp"];
            final parsed = ts != null ? DateTime.tryParse(ts)?.toLocal() : null;
            final tsStr = parsed != null ? f.format(parsed) : ts ?? "";
            return Card(
              child: ListTile(
                leading: Icon(Icons.notification_important),
                title: Text("${a["camera_id"] ?? '-'} — ${a["message"]}"),
                subtitle: Text("Value: ${a["value"]}  •  $tsStr"),
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}

/// ==== Users Tab (admin) ====
class UsersTab extends StatefulWidget {
  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<dynamic> users = [];
  bool loading = false;
  String msg = "";

  Future<void> fetchUsers() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/users"), headers: authHeaders(token));
      if (res.statusCode == 200) {
        setState(() {
          users = jsonDecode(res.body);
        });
      } else {
        setState(() {
          msg = "Failed: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final role = Provider.of<AppState>(context, listen: false).role ?? "viewer";
    if (role == "admin") fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AppState>(context).role ?? "viewer";
    if (role != "admin") {
      return Center(child: Text("Only admin can view users"));
    }
    return RefreshIndicator(
      onRefresh: fetchUsers,
      child: ListView(
        padding: EdgeInsets.all(12),
        children: [
          ElevatedButton(onPressed: fetchUsers, child: Text("Refresh users")),
          if (loading) CircularProgressIndicator(),
          if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.red)),
          ...users.map((u) {
            return Card(
              child: ListTile(
                title: Text(u["email"] ?? "-"),
                subtitle: Text("Role: ${u["role"]}  •  notify: ${u["notify"]}"),
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}

/// ==== Profile Tab (change password) ====
class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _oldCtl = TextEditingController();
  final _newCtl = TextEditingController();
  String msg = "";
  bool loading = false;

  Future<void> changePassword() async {
    setState(() {
      loading = true;
      msg = "";
    });
    final token = Provider.of<AppState>(context, listen: false).token;
    try {
      final res = await http.post(Uri.parse("$BASE_URL/auth/password/change"),
          headers: authHeaders(token),
          body: jsonEncode({"old_password": _oldCtl.text, "new_password": _newCtl.text}));
      if (res.statusCode == 200) {
        setState(() {
          msg = "Password changed";
        });
      } else {
        setState(() {
          msg = "Failed: ${res.statusCode} ${res.body}";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Provider.of<AppState>(context).email ?? "-";
    final role = Provider.of<AppState>(context).role ?? "-";
    return Padding(
      padding: EdgeInsets.all(12),
      child: ListView(
        children: [
          ListTile(title: Text("Email"), subtitle: Text(email)),
          ListTile(title: Text("Role"), subtitle: Text(role)),
          Divider(),
          Text("Change password"),
          TextField(controller: _oldCtl, decoration: InputDecoration(labelText: "Old password"), obscureText: true),
          TextField(controller: _newCtl, decoration: InputDecoration(labelText: "New password"), obscureText: true),
          SizedBox(height: 8),
          ElevatedButton(onPressed: loading ? null : changePassword, child: Text("Change password")),
          if (msg.isNotEmpty) Padding(padding: EdgeInsets.only(top: 8), child: Text(msg))
        ],
      ),
    );
  }
}
