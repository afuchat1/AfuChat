import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
  );
  runApp(AfuChatApp());
}

class AfuChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<Session?>.value(
          value: Supabase.instance.client.auth.onAuthStateChange.map((state) => state.session),
          initialData: Supabase.instance.client.auth.currentSession,
        ),
      ],
      child: MaterialApp(
        title: 'AfuChat',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = Provider.of<Session?>(context);
    return session == null ? LoginScreen() : MainNavigation();
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmail(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signInWithEmail(context),
              child: Text('Login with Email'),
            ),
            ElevatedButton(
              onPressed: () => _signInWithGoogle(context),
              child: Text('Login with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    FeedScreen(),
    ChannelsScreen(),
    MessagingScreen(),
    ProfileScreen(),
    WalletScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        ],
      ),
    );
  }
}

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed (Sponsored Enabled)')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('posts')
            .select()
            .then((response) => response as List<Map<String, dynamic>>),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.map((doc) {
              return ListTile(
                title: Text(doc['content']),
                subtitle: doc['isSponsored'] ? Text('Sponsored') : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ChannelsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Channels (With Sponsored)')),
      body: ListView(
        children: [
          ListTile(title: Text('Channel 1'), subtitle: Text('Description')),
          SponsoredAdWidget(),
          ListTile(title: Text('Channel 2'), subtitle: Text('Description')),
        ],
      ),
    );
  }
}

class SponsoredAdWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.yellow),
          SizedBox(width: 8),
          Text('Sponsored: Check out this cool product!'),
        ],
      ),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _aiSuggestion = '';

  Future<void> _getAISuggestion(String input) async {
    if (input.isEmpty) {
      setState(() => _aiSuggestion = '');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/distilbert-base-uncased-finetuned-sst-2-english'),
        headers: {
          'Authorization': 'Bearer YOUR_HF_API_KEY', // Replace with your Hugging Face API key
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': input}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() => _aiSuggestion = result[0]['label'] == 'POSITIVE' ? 'Sounds positive!' : 'Sounds negative.');
      }
    } catch (e) {
      setState(() => _aiSuggestion = 'Error fetching suggestion');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messaging & Calls')),
      body: Column(
        children: [
          Expanded(child: Center(child: Text('Chat List Here'))),
          if (_aiSuggestion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('AI Suggestion: $_aiSuggestion', style: TextStyle(color: Colors.blue)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Type a message'),
                    onChanged: _getAISuggestion,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile (Referral Points, Support, AI)')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Referral Points'),
            subtitle: Text('You have 150 points'),
            trailing: Icon(Icons.card_giftcard),
