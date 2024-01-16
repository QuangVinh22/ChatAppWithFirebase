import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _AuthScreen();
  }
}

class _AuthScreen extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassWord = '';
  var _enteredUsername = '';
  var _isLogin = true;

  File? _selectedImage;

  var _isAuthenticating = false;
  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      //show error message
      return;
    }
    _form.currentState!.save();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        //xử lý đăng nhập
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassWord);
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('User login successfully!'),
          ),
        );
      } else {
        //xử lý đăng ký
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassWord);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        // Thêm kiểm tra mounted ở đây
        await storageRef.putFile(_selectedImage!);
        final imageURL = await storageRef.getDownloadURL();

        // Tạo 1 thư mục chứa thông tin của người dùng sau đó ném lên firebase

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageURL,
        });
        if (!mounted) return;

        // Sử dụng ScaffoldMessenger bằng cách truy cập context hiện tại
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String errorMessage = 'Authentication failed.';
      if (error.message != null) errorMessage = error.message!;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 20, left: 20),
                width: 200,
                child: Image.asset(
                  'assets/images/chat.png',
                ),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Khi và chỉ khi người dùng ở trong mode đăng ký mới được chọn hình ảnh làm avatar
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            //Form nhập email
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: "Email Address"),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return "Please enter a valid email address";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                            ),
                            // Tạo Form cho người dùng nhập User Name
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                    labelText: "UserName"),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.length < 4) {
                                    return "Please enter at least 4 characters.";
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredUsername = value!;
                                },
                              ),
                            //Form nhập mật khẩu với validation
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: "Password"),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a password";
                                } else if (value.length < 8) {
                                  return "Password must be at least 8 characters long";
                                } else if (!RegExp(r'(?=.*?[0-9])')
                                    .hasMatch(value)) {
                                  return "Password must have at least one number";
                                } else if (!RegExp(r'(?=.*?[A-Za-z])')
                                    .hasMatch(value)) {
                                  return "Password must have at least one letter";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassWord = value!;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            // nếu như đang load thì che các nút đi để lại cái đang load
                            if (_isAuthenticating)
                              const CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
                                child: Text(_isLogin ? "Login" : "Signup"),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? "Create an account"
                                    : "I already have an account"),
                              ),
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
