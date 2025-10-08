import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nurox_chat/auth/login/login.dart';
import 'package:nurox_chat/auth/register/register.dart';
import 'package:nurox_chat/utils/constants.dart';

class Landing extends StatefulWidget {
  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: ClipRRect(
                    // 1. Define the radius you want to apply to the corners
                    borderRadius:
                        BorderRadius.circular(20.0), // Example radius of 20
                    child: Image.asset(
                      'assets/icon/logo.jpg',
                      height: 200.0,
                      width: 200.0,
                      fit: BoxFit.cover,
                    ),
                  )),
            ),
            Text(
              Constants.appName,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 22.0,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Ubuntu-Regular',
                  ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        elevation: 0.0,
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => Login(),
                    ),
                  );
                },
                child: Container(
                  height: 45.0,
                  width: 130.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40.0),
                    border: Border.all(color: Colors.grey),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Theme.of(context).primaryColor,
                        Constants.greenMid,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => Register(),
                    ),
                  );
                },
                child: Container(
                  height: 45.0,
                  width: 130.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40.0),
                    border: Border.all(color: Theme.of(context).primaryColor),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Theme.of(context).primaryColor,
                        Constants.greenMid,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'SIGN UP',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
