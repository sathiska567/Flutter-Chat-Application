import 'dart:io';

import 'package:chat_app/widget/user_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  final _formKey =
      GlobalKey<FormState>(); // this key should use to access the form

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  Future<void> _submitForm() async {
    final isValid =
        _formKey.currentState?.validate(); // this will validate the form

    if (isValid == null || !isValid) {
      return;
    }

    if (!_isLogin && _selectedImage == null) {
      return;
    }

    _formKey.currentState?.save(); // this will save the form

    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        // log user into the system
        final userCredential = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        print(userCredential);
      } else {
        // sign user up
        // this method sends the HTTP request to the Firebase SDK.
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        print(userCredential);

        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_image')
              .child('${userCredential.user!.uid}.jpg');

          await storageRef.putFile(_selectedImage!);
          final getDownLoadUrl = await storageRef.getDownloadURL();

          print(getDownLoadUrl);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'userName': _enteredUsername,
            'email': _enteredEmail,
            'imgUrl':
                getDownLoadUrl // Assuming getDownLoadUrl is an asynchronous function
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // show error message
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication Failed')),
      );

      setState(() {
        _isAuthenticating = false;
      });
    } catch (e) {
      // Handle other exceptions
    }
  }

  @override
  Widget build(BuildContext context) {
    // Implement your widget tree here
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 50,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(onImagePick: (pickedImage) {
                              _selectedImage = pickedImage;
                            }),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: "Email Address"),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return "Please Enter Valid Email Address";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                         if (!_isLogin)
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "User Name"),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 4) {
                                return "Please Enter Valid UserName (at least 4 characters)";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredUsername = newValue!;
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            decoration:
                                const InputDecoration(labelText: "Password"),
                            obscureText: true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 6) {
                                return "Password Must be at least 6 characters long";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredPassword = newValue!;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Visibility(
                visible: _isAuthenticating,
                child: Container(
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
              Visibility(
                visible: !_isAuthenticating,
                child: ElevatedButton(
                  onPressed: () {
                    _submitForm();
                  },
                  child: Text(_isLogin ? "Login" : "SignUp"),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? "Create an account"
                      : "I Already have an account. Login",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
