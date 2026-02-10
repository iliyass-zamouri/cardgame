import 'package:shadow_hand/GameState_VM.dart';
import 'package:shadow_hand/gen/assets.gen.dart';
import 'package:shadow_hand/background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:shadow_hand/services/auth_service.dart';
import 'package:shadow_hand/screens/auth/login_screen.dart';

class StartGameWidget extends StatefulWidget {
  final int userId;
  final String username;
  final int totalPoints;

  const StartGameWidget({
    Key? key,
    required this.userId,
    required this.username,
    required this.totalPoints,
  }) : super(key: key);

  @override
  State<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends State<StartGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  // Multiplayer state
  late WebSocketChannel _channel;
  bool _isConnected = false;
  String? _roomCode;
  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;
  final _roomCodeController = TextEditingController();
  bool _isInWaitlist = false;
  bool _isSearchingForMatch = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _startAnimations();
  }

  void _initializeWebSocket() {
    final String wsUrl = Platform.isAndroid 
        ? 'ws://10.0.2.2:8080' 
        : 'ws://localhost:8080';
    
    print('Initializing WebSocket connection to: $wsUrl');
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel.stream.listen((message) {
      print('WebSocket message received: $message');
      _handleWebSocketMessage(message);
    }, onError: (error) {
      print('WebSocket error: $error');
      setState(() => _isConnected = false);
    }, onDone: () {
      print('WebSocket disconnected');
      setState(() => _isConnected = false);
    });

    // Authenticate with server
    print('Sending authentication for user: ${widget.userId}');
    _channel.sink.add(jsonEncode({
      'type': 'authenticate',
      'userId': widget.userId
    }));
  }

  void _handleWebSocketMessage(String message) {
    print('🔥 WebSocket message received: $message');
    final data = jsonDecode(message);
    print('🔍 Message type: ${data['type']}');
    
    switch (data['type']) {
      case 'authenticated':
        print('✅ Authentication successful');
        setState(() => _isConnected = true);
        break;
      case 'roomCreated':
        print('🏠 Room created response received: $data');
        setState(() {
          _isCreatingRoom = false;
          _roomCode = data['roomCode'];
        });
        print('🏠 Room code set to: ${data['roomCode']}');
        print('🏠 Showing room code overlay');
        break;
      case 'roomCancelled':
        print('🏠 Room cancelled confirmed by server');
        setState(() {
          _roomCode = null;
        });
        print('🏠 State updated. _roomCode = $_roomCode');
        break;
      case 'gameStart':
        print('🎮 Game start received: $data');
        _showGameStartDialog(data['players']);
        break;
      case 'matchFound':
        print('🎯 Match found: $data');
        _showMatchFoundDialog(data['opponent']);
        break;
      case 'waitlistJoined': // FIXED: Changed from 'joinedWaitlist' to 'waitlistJoined'
        print('⏳ Waitlist joined message received!');
        print('⏳ Setting _isInWaitlist = true');
        setState(() {
          _isInWaitlist = true;
          _isSearchingForMatch = false;
        });
        print('⏳ State updated. _isInWaitlist = $_isInWaitlist');
        break;
      case 'leftWaitlist':
      case 'waitlistLeft': // Handle both message types from server
        print('🚪 Left waitlist confirmed by server');
        setState(() {
          _isInWaitlist = false;
          _isSearchingForMatch = false;
        });
        print('🚪 State updated. _isInWaitlist = $_isInWaitlist');
        break;
      case 'error':
        print('❌ Error received: ${data['message']}');
        _showErrorDialog(data['message']);
        break;
      default:
        print('❓ Unknown message type: ${data['type']}');
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building widget. _isInWaitlist = $_isInWaitlist, _roomCode = $_roomCode');
    
    return MaterialApp(
      home: Material(
        child: GameBackground(
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 40),
                            _buildTitle(),
                            const SizedBox(height: 20),
                            _buildUserInfo(),
                            const SizedBox(height: 40),
                            _buildPlayButton(),
                            const SizedBox(height: 20),
                            _buildMultiplayerButtons(),
                            const SizedBox(height: 20),
                            _buildAdditionalButtons(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Room code overlay - full screen overlay
              if (_roomCode != null) _buildRoomCodeOverlay(),
              // Waitlist overlay - blocks interaction
              if (_isInWaitlist) _buildWaitlistOverlay(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.yellow.shade400,
            Colors.orange.shade500,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.casino,
        size: 50,
        color: Colors.white,
      ),
    );
  }
  
  Widget _buildTitle() {
    return const Text(
      'Shadow Hand',
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Welcome, ${widget.username}!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Points: ${widget.totalPoints}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerButtons() {
    return Column(
      children: [
        _buildMultiplayerButton(
          _isCreatingRoom ? '🔄 Creating Room...' : '👥 Play with Friend',
          _isCreatingRoom ? () {} : () => _createRoom(),
          _isCreatingRoom ? Colors.grey : Colors.purple,
        ),
        const SizedBox(height: 15),
        _buildMultiplayerButton(
          '🎯 Join Room',
          () => _showJoinRoomDialog(),
          Colors.blue,
        ),
        const SizedBox(height: 15),
        _buildMultiplayerButton(
          '⚡ Quick Match',
          () => _joinWaitlist(),
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMultiplayerButton(String text, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) {
        setState(() {});
        onPressed();
      },
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitlistOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7), // Semi-transparent overlay
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 3,
                        backgroundColor: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      '🔍 Searching for opponent...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'We\'ll find you a match soon!\nThis may take a few moments...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _leaveWaitlist,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Cancel Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitlistStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 3,
                  backgroundColor: Colors.orange.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                '🔍 Searching for opponent...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'We\'ll find you a match soon!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _leaveWaitlist,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the room code provided by your friend:'),
            const SizedBox(height: 20),
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(),
              ),
              maxLength: 8,
            ),
            const SizedBox(height: 20),
            if (_isJoiningRoom)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _joinRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Join'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCodeOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8), // Semi-transparent overlay
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏠 Room Created',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelRoomCreation,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Share this code with your friend:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        _roomCode ?? '',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Copy to clipboard functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room code copied!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Waiting for opponent to join...\nThis room will be cancelled if you close it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Copy room code to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room code copied!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green.withOpacity(0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Copy Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelRoomCreation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red.withOpacity(0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cancel Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cancelRoomCreation() {
    print('❌ Cancel room creation button pressed');
    print('❌ Room code to cancel: $_roomCode');
    
    // Send cancel room message to server
    if (_roomCode != null) {
      print('❌ Sending cancelRoom message to server');
      _channel.sink.add(jsonEncode({
        'type': 'cancelRoom',
        'roomCode': _roomCode,
      }));
    }
    
    // Update local state immediately for better UX
    setState(() {
      _roomCode = null;
    });
    
    print('❌ State updated. _roomCode = $_roomCode');
    print('❌ Room cancelled successfully');
  }

  void _showGameStartDialog(List<dynamic> players) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Starting!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Players:'),
            ...players.map((player) => Text(
              '• ${player['username']} (${player['totalPoints']} pts)',
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start the actual game
              context.read<GameViewModel>().newGame();
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  void _showMatchFoundDialog(Map<String, dynamic> opponent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Match Found!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Opponent: ${opponent['username']}'),
            Text('Points: ${opponent['totalPoints']}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start the actual game
              context.read<GameViewModel>().newGame();
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createRoom() {
    print('Create room button pressed');
    print('WebSocket connected: $_isConnected');
    print('Channel status: ${_channel.closeCode}');
    
    if (!_isConnected) {
      print('WebSocket not connected, cannot create room');
      _showErrorDialog('Not connected to server. Please check your connection.');
      setState(() => _isCreatingRoom = false);
      return;
    }
    
    setState(() => _isCreatingRoom = true);
    print('Sending createRoom message to server');
    _channel.sink.add(jsonEncode({'type': 'createRoom'}));
  }

  void _joinRoom() {
    if (_roomCodeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a room code');
      return;
    }
    
    setState(() => _isJoiningRoom = true);
    _channel.sink.add(jsonEncode({
      'type': 'joinRoom',
      'roomCode': _roomCodeController.text.trim()
    }));
  }

  void _joinWaitlist() {
    print('🚀 Join waitlist button pressed');
    print('🚀 WebSocket connected: $_isConnected');
    setState(() => _isSearchingForMatch = true);
    print('🚀 Sending joinWaitlist message to server');
    _channel.sink.add(jsonEncode({'type': 'joinWaitlist'}));
    print('🚀 joinWaitlist message sent');
  }

  void _leaveWaitlist() {
    print('❌ Cancel search button pressed');
    print('❌ Sending leaveWaitlist message to server');
    
    // Send leave waitlist message to server
    _channel.sink.add(jsonEncode({'type': 'leaveWaitlist'}));
    
    // Update local state immediately for better UX
    setState(() {
      _isInWaitlist = false;
      _isSearchingForMatch = false;
    });
    
    print('❌ State updated. _isInWaitlist = $_isInWaitlist');
    print('❌ Left waitlist successfully');
  }

  Future<void> _logout() async {
    try {
      // Clear stored user data
      await AuthService.clearUserData();
      
      // Close WebSocket connection
      _channel.sink.close();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildPlayButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        // Add user to waitlist for matchmaking instead of single player
        _joinWaitlist();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()
          ..translate(0.0, _isPressed ? 4.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPressed
                  ? [
                      Colors.green.shade600,
                      Colors.green.shade700,
                      Colors.green.shade800,
                    ]
                  : [
                      Colors.green.shade400,
                      Colors.green.shade500,
                      Colors.green.shade600,
                    ],
            ),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 45,
              vertical: _isPressed ? 14 : 18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: _isPressed ? 28 : 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'FIND MATCH',
                  style: TextStyle(
                    fontSize: _isPressed ? 20 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAdditionalButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSecondaryButton(
          'How to Play',
          () => _showHowToPlay(),
        ),
        _buildSecondaryButton(
          'Settings',
          () => _showSettings(),
        ),
        _buildSecondaryButton(
          'Logout',
          () => _logout(),
        ),
      ],
    );
  }
  
  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Shadow Hand!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text('1. Click "Play Game" to start'),
              Text('2. Draw cards from the deck'),
              Text('3. Match cards with the same value'),
              Text('4. Use special cards strategically'),
              Text('5. First to empty their hand wins!'),
              SizedBox(height: 15),
              Text(
                'Special Cards:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Jack: Reveal a hidden card'),
              Text('• Queen: Switch or shuffle cards'),
              Text('• King: Higher value in black suits'),
              Text('• Joker: Wild card with -1 value'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
  
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.volume_up),
              title: Text('Sound Effects'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Background Music'),
              trailing: Switch(value: false, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.vibration),
              title: Text('Vibration'),
              trailing: Switch(value: true, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
