import 'package:flutter/material.dart';
import 'package:campus_pulse/auth/auth_manager.dart';
import 'package:campus_pulse/screens/main_screen.dart';
import 'package:campus_pulse/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  bool _isLogin = true;
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _nicknameController.clear();
    _errorMessage = null;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = await DefaultAuthManager.instance.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign in failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nicknameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = await DefaultAuthManager.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Sign up failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign up failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwipzeeColors.white,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomePage(),
            _buildAuthPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SwipzeeColors.mintGreen, SwipzeeColors.fireOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // App Title
          Text(
            'aftercls',
            style: SwipzeeTypography.heading1.copyWith(
              color: SwipzeeColors.darkGray,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            'Rate, Match, and Connect with Your Campus Community',
            style: SwipzeeTypography.bodyLarge.copyWith(
              color: SwipzeeColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 60),
          
          // Get Started Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SwipzeeColors.mintGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Get Started',
                style: SwipzeeTypography.buttonLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(
                Icons.arrow_back,
                color: SwipzeeColors.darkGray,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Auth Title
          Text(
            _isLogin ? 'Welcome Back!' : 'Create Account',
            style: SwipzeeTypography.heading2.copyWith(
              color: SwipzeeColors.darkGray,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _isLogin 
                ? 'Sign in to continue your campus journey'
                : 'Join the campus community today',
            style: SwipzeeTypography.bodyMedium.copyWith(
              color: SwipzeeColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Email Field
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Nickname Field (only for sign up)
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Nickname',
                hintText: 'Choose a nickname',
                prefixIcon: const Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SwipzeeColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SwipzeeColors.error.withOpacity(0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: SwipzeeTypography.bodySmall.copyWith(
                  color: SwipzeeColors.error,
                ),
              ),
            ),
          
          // Auth Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isLogin ? _signIn : _signUp),
              style: ElevatedButton.styleFrom(
                backgroundColor: SwipzeeColors.mintGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isLogin ? 'Sign In' : 'Create Account',
                      style: SwipzeeTypography.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Toggle Auth Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? "Don't have an account? " : "Already have an account? ",
                style: SwipzeeTypography.bodyMedium.copyWith(
                  color: SwipzeeColors.mediumGray,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _clearFields();
                  });
                },
                child: Text(
                  _isLogin ? 'Sign Up' : 'Sign In',
                  style: SwipzeeTypography.bodyMedium.copyWith(
                    color: SwipzeeColors.mintGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
