import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nurox_chat/view_models/theme/theme_view_model.dart';

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    // Get the current theme's TextTheme once
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.keyboard_backspace),
        ),
        // NOTE: The title style is often best left to the AppBarTheme set in Constants
        title: Text(
          "Settings",
          // Fix 1: Removed explicit TextStyle() to rely on AppBarTheme.titleTextStyle
          // or use: style: textTheme.titleLarge,
        ),
      ),
      // NOTE: Scaffold background color is better set using Theme.of(context).scaffoldBackgroundColor
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                "About",
                // Fix 2: Use the theme's title style and copy to apply w900,
                // which will respect the text color set in your darkTheme's textTheme.
                style: textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                "A Fully Functional Social Media Application Made by ISIC Team",
                // Fix 3: Rely on the default subtitle style from the theme
                style: textTheme.titleSmall,
              ),
              trailing: Icon(Icons.error),
            ),
            Divider(),
            ListTile(
              title: Text(
                "Dark Mode",
                // Fix 4: Apply w900 by copying the theme's default style
                style: textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                "Use the dark mode",
                // Fix 5: Rely on the default subtitle style from the theme
                style: textTheme.titleSmall,
              ),
              trailing: Consumer<ThemeProvider>(
                builder: (context, notifier, child) => CupertinoSwitch(
                  onChanged: (val) {
                    notifier.toggleTheme();
                  },
                  value: notifier.dark,
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
