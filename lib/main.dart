import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_loading_screen.dart';
import 'firebase_options.dart';

import 'app_gateway.dart';
import 'developer_admin_page.dart';
import 'legal_content.dart';
import 'legal_document_page.dart';
import 'login_page.dart';
import 'platform_runtime_gate.dart';
import 'public_web_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _resolveInitialRoute() {
    if (!kIsWeb) {
      return '/boot';
    }

    final rawPath = Uri.base.path.trim();
    if (rawPath.isEmpty || rawPath == '/' || rawPath == '/index.html') {
      return '/';
    }

    final normalized = rawPath.endsWith('/')
        ? rawPath.substring(0, rawPath.length - 1)
        : rawPath;
    return normalized.isEmpty ? '/' : normalized;
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = const PublicWebHomePage();
        break;
      case '/login':
        page = const LoginPage();
        break;
      case '/app':
        page = const AppGateway();
        break;
      case '/boot':
        page = const SplashScreen();
        break;
      case '/workspace':
        page = const DeveloperAdminGatePage();
        break;
      case '/terms':
        page = const LegalDocumentPage(
          title: termsDocumentTitle,
          subtitle: termsDocumentSubtitle,
          sections: termsDocumentSections,
        );
        break;
      case '/privacy':
        page = const LegalDocumentPage(
          title: privacyDocumentTitle,
          subtitle: privacyDocumentSubtitle,
          sections: privacyDocumentSections,
        );
        break;
      default:
        page = kIsWeb ? const PublicWebHomePage() : const AppGateway();
        break;
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartLaba',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.unboundedTextTheme(),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          PlatformRuntimeGate(child: child ?? const SizedBox.shrink()),
      initialRoute: _resolveInitialRoute(),
      onGenerateRoute: _buildRoute,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed('/app');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppLoadingScreen(message: 'Menyiapkan workspace Anda...');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
