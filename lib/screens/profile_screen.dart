  import 'package:flutter/material.dart';
  import '../theme/app_colors.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'login_screen.dart';


  class ProfileScreen extends StatelessWidget {
    ProfileScreen({super.key});
    final user =
        Supabase.instance.client.auth.currentUser;


    @override
    Widget build(BuildContext context) {

      return FutureBuilder(
        future: Supabase.instance.client
            .from('profiles')
            .select()
            .eq('email', user?.email ?? '')
            .maybeSingle(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(snapshot.error.toString()),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final profile = snapshot.data;

          return Scaffold(
            backgroundColor: AppColors.cream,

            appBar: AppBar(
              backgroundColor: AppColors.navyBlue,
              title: const Text(
                "Teacher Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            body: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [

                  const SizedBox(height:20),

                  const CircleAvatar(
                    radius:50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size:50,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height:15),

                  Text(
                    "${profile?['title'] ?? ''} ${profile?['full_name'] ?? 'No Name'}",
                    style: const TextStyle(
                      fontSize:24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    user?.email ?? "No Email",
                    style: TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height:30),

                  profileTile(
                    Icons.school,
                    "School",
                    profile?['school_name'] ?? 'No School',
                  ),

                  profileTile(
                    Icons.menu_book,
                    "Subjects",
                    ((profile?['subjects'] ?? []) as List).join(', '),
                  ),

                  profileTile(
                    Icons.groups,
                    "Classes",
                    ((profile?['classes'] ?? []) as List).join(', '),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () async {

                        await Supabase.instance.client.auth.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.red,
                      ),

                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    Widget profileTile(
        IconData icon,
        String title,
        String value){

      return ListTile(
        leading: Icon(
          icon,
          color: AppColors.navyBlue,
        ),

        title: Text(title),
        subtitle: Text(value),
      );
    }
  }