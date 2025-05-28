import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zcezlehzequzatfbnnhc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjZXpsZWh6ZXF1emF0ZmJubmhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NDAwMDMsImV4cCI6MjA2NDAxNjAwM30.8SitRl9rZAS6ADEryjXpsWMdR1kG5Y8v0bowo053rd4',
  );
  runApp(const AfuChatApp());
}

class AfuChatApp extends StatelessWidget {
  const AfuChatApp({super.key});

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
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<Session?>(context);
    return session == null ? const LoginScreen() : const MainNavigation();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithEmail(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://zcezlehzequzatfbnnhc.supabase.co/auth/v1/callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _signInWithEmail(context),
                        child: const Text('Login with Email'),
                      ),
                      ElevatedButton(
                        onPressed: () => _signInWithGoogle(context),
                        child: const Text('Login with Google'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const FeedScreen(),
    const ChannelsScreen(),
    const MessagingScreen(),
    const ProfileScreen(),
    const WalletScreen(),
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
        items: const [
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

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _postsFuture = Supabase.instance.client
          .from('posts')
          .select()
          .then((response) => response as List<Map<String, dynamic>>)
          .catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
        }
        return [] as List<Map<String, dynamic>>;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed (Sponsored Enabled)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available'));
          }
          return RefreshIndicator(
            onRefresh: _fetchPosts,
            child: ListView(
              children: snapshot.data!.map((doc) {
                return ListTile(
                  title: Text(doc['content']),
                  subtitle: doc['isSponsored'] ? const Text('Sponsored') : null,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Channels (With Sponsored)')),
      body: ListView(
        children: const [
          ListTile(title: Text('Channel 1'), subtitle: Text('Description')),
          SponsoredAdWidget(),
          ListTile(title: Text('Channel 2'), subtitle: Text('Description')),
        ],
      ),
    );
  }
}

class SponsoredAdWidget extends StatelessWidget {
  const SponsoredAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: const Row(
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
  const MessagingScreen({super.key});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String _aiSuggestion = '';
  bool _isLoading = false;

  Future<void> _getAISuggestion(String input) async {
    if (input.isEmpty) {
      setState(() => _aiSuggestion = '');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/distilbert-base-uncased-finetuned-sst-2-english'),
        headers: {
          'Authorization': 'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': input}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _aiSuggestion = result[0]['label'] == 'POSITIVE' ? 'Sounds positive!' : 'Sounds negative.';
        });
      } else {
        setState(() => _aiSuggestion = 'Error: Unable to analyze sentiment');
      }
    } catch (e) {
      setState(() => _aiSuggestion = 'Error fetching suggestion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'sentiment': _aiSuggestion,
      });
      _messageController.clear();
      _aiSuggestion = '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messaging & Calls')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ListTile(
                        title: Text(message['text']!),
                        subtitle: message['sentiment']!.isNotEmpty
                            ? Text('AI: ${message['sentiment']}')
                            : null,
                      );
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_aiSuggestion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('AI Suggestion: $_aiSuggestion', style: const TextStyle(color: Colors.blue)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Type a message'),
                    onChanged: _getAISuggestion,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
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
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile (Referral Points, Support, AI)')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Referral Points'),
            subtitle: Text('You have 150 points'),
            trailing: Icon(Icons.card_giftcard),
          ),
          ListTile(
            title: const Text('Support'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          ListTile(
            title: const Text('AI Assistant'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen())),
          ),
          const LanguageSelectorWidget(),
          const ContentReportWidget(),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: const Center(child: Text('Contact Support')),
    );
  }
}

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: const Center(child: Text('Ask me anything!')),
    );
  }
}

class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Language'),
      subtitle: const Text('English'),
      trailing: const Icon(Icons.language),
      onTap: () {
        // Implement language switching logic
      },
    );
  }
}

class ContentReportWidget extends StatelessWidget {
  const ContentReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Report Content'),
      trailing: const Icon(Icons.report),
      onTap: () {
        // Implement content reporting logic
      },
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet (Deposit, Withdraw, Ads)')),
      body: ListView(
        children: [
          const ListTile(title: Text('Balance: \$50')),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Deposit'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Withdraw'),
          ),
          const SponsoredAdWidget(),
        ],
      ),
    );
  }
}
