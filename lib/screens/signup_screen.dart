import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {

  final _formKey =
  GlobalKey<FormState>();

  final TextEditingController
  emailController =
  TextEditingController();

  final TextEditingController
  fullNameController =
  TextEditingController();

  String selectedTitle = "Mr";

  final TextEditingController
  schoolController =
  TextEditingController();

  final TextEditingController
  subjectController =
  TextEditingController();

  List<String> subjects = [];

  final TextEditingController classController =
  TextEditingController();

  List<String> classes = [];

  final TextEditingController
  passwordController =
  TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      AppColors.cream,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Padding(
            padding:
            const EdgeInsets.all(25),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const SizedBox(height:40),

                  /// TITLE
                  Text(
                    "Create Account",

                    style: TextStyle(
                      fontSize:32,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      AppColors.navyBlue,
                    ),
                  ),

                  const SizedBox(height:10),

                  Text(
                    "Sign up to continue using GradeLens",

                    style: TextStyle(
                      fontSize:16,
                      color:
                      AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height:40),

                  TextFormField(

                    controller:
                    fullNameController,

                    decoration: InputDecoration(

                      labelText: "Full Name",

                      prefixIcon:
                      const Icon(Icons.person),

                      filled: true,
                      fillColor: Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                    ),

                    validator: (value){

                      if(value == null ||
                          value.isEmpty){

                        return
                          "Please enter full name";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField(

                    value: selectedTitle,

                    decoration: InputDecoration(

                      labelText: "Preferred Title",

                      filled: true,
                      fillColor: Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                    ),

                    items: const [

                      DropdownMenuItem(
                        value: "Mr",
                        child: Text("Mr"),
                      ),

                      DropdownMenuItem(
                        value: "Ms",
                        child: Text("Ms"),
                      ),

                      DropdownMenuItem(
                        value: "Mrs",
                        child: Text("Mrs"),
                      ),

                    ],

                    onChanged: (value){

                      selectedTitle = value!;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// EMAIL
                  TextFormField(
                    controller:
                    emailController,

                    decoration:
                    InputDecoration(

                      labelText:
                      "Email",

                      prefixIcon:
                      Icon(Icons.email),

                      filled:true,
                      fillColor:
                      Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                            15),
                      ),
                    ),

                    validator: (value) {

                      if(value == null ||
                          value.isEmpty){

                        return
                          "Please enter email";
                      }

                      if(!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+',
                      ).hasMatch(value)){

                        return
                          "Enter valid email";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height:20),

                  /// SCHOOL
                  TextFormField(
                    controller:
                    schoolController,

                    decoration:
                    InputDecoration(

                      labelText:
                      "School Name",

                      prefixIcon:
                      Icon(Icons.school),

                      filled:true,
                      fillColor:
                      Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                            15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    TextField(
                      controller: subjectController,

                      decoration: InputDecoration(
                        labelText: "Add Subject",

                        prefixIcon:
                        const Icon(Icons.menu_book),

                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),

                          onPressed: () {

                            if (subjectController
                                .text
                                .trim()
                                .isNotEmpty) {

                              setState(() {

                                subjects.add(
                                  subjectController
                                      .text
                                      .trim(),
                                );

                              });

                              subjectController.clear();
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,

                      children:
                      subjects.map((subject) {

                        return Chip(
                          label: Text(subject),

                          deleteIcon:
                          const Icon(Icons.close),

                          onDeleted: () {

                            setState(() {
                              subjects.remove(subject);
                            });

                          },
                        );

                      }).toList(),
                    ),
                  ],
                ),

                  const SizedBox(height:20),

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      TextField(
                        controller: classController,

                        decoration: InputDecoration(
                          labelText: "Add Class",

                          prefixIcon:
                          const Icon(Icons.groups),

                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),

                            onPressed: () {

                              if (classController
                                  .text
                                  .trim()
                                  .isNotEmpty) {

                                setState(() {

                                  classes.add(
                                    classController
                                        .text
                                        .trim(),
                                  );

                                });

                                classController.clear();
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,

                        children:
                        classes.map((className) {

                          return Chip(
                            label: Text(className),

                            deleteIcon:
                            const Icon(Icons.close),

                            onDeleted: () {

                              setState(() {
                                classes.remove(className);
                              });

                            },
                          );

                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height:20),

                  /// PASSWORD
                  TextFormField(
                    controller:
                    passwordController,

                    obscureText:
                    obscurePassword,

                    decoration:
                    InputDecoration(

                      labelText:
                      "Password",

                      prefixIcon:
                      Icon(Icons.lock),

                      suffixIcon:
                      IconButton(

                        icon: Icon(

                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,

                        ),

                        onPressed: () {

                          setState(() {

                            obscurePassword =
                            !obscurePassword;

                          });

                        },
                      ),

                      filled:true,
                      fillColor:
                      Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                            15),
                      ),
                    ),

                    validator: (value) {

                      if(value == null ||
                          value.isEmpty){

                        return
                          "Please enter password";
                      }

                      String password =
                      value.trim();

                      final hasUppercase =
                      password.contains(
                        RegExp(r'[A-Z]'),
                      );

                      final hasLowercase =
                      password.contains(
                        RegExp(r'[a-z]'),
                      );

                      final hasDigit =
                      password.contains(
                        RegExp(r'[0-9]'),
                      );

                      final hasSpecial =
                      password.contains(
                        RegExp(
                          r'[!@#$%^&*(),.?":{}|<>]',
                        ),
                      );

                      if(password.length < 5){

                        return
                          "Minimum 5 characters";
                      }

                      if(!hasUppercase){

                        return
                          "Need uppercase letter";
                      }

                      if(!hasLowercase){

                        return
                          "Need lowercase letter";
                      }

                      if(!hasDigit){

                        return
                          "Need number";
                      }

                      if(!hasSpecial){

                        return
                          "Need special character";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height:15),

                  /// PASSWORD RULES
                  Container(
                    padding:
                    const EdgeInsets.all(15),

                    decoration:
                    BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(
                          15),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: const [

                        Text(
                          "Password Requirements",

                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(height:8),

                        Text(
                            "• Minimum 5 characters"),

                        Text(
                            "• 1 uppercase letter"),

                        Text(
                            "• 1 lowercase letter"),

                        Text(
                            "• 1 number"),

                        Text(
                            "• 1 special character"),

                      ],
                    ),
                  ),

                  const SizedBox(height:35),

                  /// SIGN UP BUTTON
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(

                      style:
                      ElevatedButton.styleFrom(

                        backgroundColor:
                        AppColors.navyBlue,

                        padding:
                        const EdgeInsets.symmetric(
                          vertical:18,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              15),
                        ),
                      ),

                      onPressed: () async {

                        if(_formKey
                            .currentState!
                            .validate()){

                          try {

                            final response =
                                await Supabase.instance.client.auth.signUp(

                              email:
                              emailController.text.trim(),

                              password:
                              passwordController.text.trim(),

                            );

                            if(response.user != null){

                              await Supabase.instance.client
                                  .from('profiles')
                                  .insert({

                                'full_name':
                                fullNameController.text.trim(),

                                'title':
                                selectedTitle,

                                'school_name':
                                schoolController.text.trim(),

                                'subjects': subjects,

                                'classes': classes,

                                'email':
                                emailController.text.trim(),

                              });

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(

                                const SnackBar(
                                  content: Text(
                                    "Signup Successful!",
                                  ),
                                ),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(),
                                ),
                              );

                            }

                          } catch (e) {

                            ScaffoldMessenger.of(context)
                                .showSnackBar(

                              SnackBar(
                                content: Text(
                                  e.toString(),
                                ),
                              ),
                            );

                          };

                        }

                      },

                      child: const Text(
                        "Sign Up",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize:18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height:20),

                  /// LOGIN TEXT
                  Center(
                    child: TextButton(

                      onPressed: () {

                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                            LoginScreen(),
                          ),
                        );

                      },

                      child: Text(
                        "Already have an account? Login",

                        style: TextStyle(
                          color:
                          AppColors.navyBlue,
                        ),
                      ),
                    ),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}