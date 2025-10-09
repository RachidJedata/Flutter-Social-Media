import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:nurox_chat/screens/mainscreen.dart';
import 'package:provider/provider.dart';
import 'package:nurox_chat/components/password_text_field.dart';
import 'package:nurox_chat/components/text_form_builder.dart';
import 'package:nurox_chat/utils/validation.dart';
import 'package:nurox_chat/view_models/auth/register_view_model.dart';
import 'package:nurox_chat/widgets/indicators.dart';
// classe register 
class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();  // Création de l'état associé
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    RegisterViewModel viewModel = Provider.of<RegisterViewModel>(context);   // On récupère le ViewModel via Provider
    return LoadingOverlay(
      progressIndicator: circularProgress(context),
      isLoading: viewModel.loading,  // Indicateur de chargement affiché lors du traitement d'inscription
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              true, // affiche automatiquement la flèche de retour
          elevation: 0,
          backgroundColor: Colors.transparent, 
          iconTheme: IconThemeData(color: Colors.black), 
        ),
        key: viewModel.scaffoldKey,  // clé pour gérer les messages
        body: ListView(  // Corps principal de la page
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 27),
            Text(  // Message d'accueil principal
              'Welcome to Raja Chat\nCreate a new account and connect with friends',
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                fontSize: 25.0,
              ),
            ),
            SizedBox(height: 30.0),
            buildForm(viewModel, context),   // Appel du formulaire d'inscription
            SizedBox(height: 30.0),
            Row(    // Lien vers la page de connexion
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account ? ',
                ),
                GestureDetector(   // Texte cliquable pour retourner à la page précédente (Login)
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buildForm(RegisterViewModel viewModel, BuildContext context) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,  // validation automatique
      child: Column(
        children: [
          TextFormBuilder(  // // Champ : Nom d'utilisateur
            enabled: !viewModel.loading,
            prefix: Ionicons.person_outline,
            hintText: "Username",
            textInputAction: TextInputAction.next,
            validateFunction: Validations.validateName,
            onSaved: (String val) {
              viewModel.setName(val);  // sauvegarde du nom dans le ViewModel
            },
            focusNode: viewModel.usernameFN,   // focus actuel
            nextFocusNode: viewModel.emailFN, // focus suivant
          ),
          SizedBox(height: 20.0),
          TextFormBuilder(     //Champ : Email
            enabled: !viewModel.loading,
            prefix: Ionicons.mail_outline,  
            hintText: "Email",
            textInputAction: TextInputAction.next,
            validateFunction: Validations.validateEmail,
            onSaved: (String val) {
              viewModel.setEmail(val);
            },
            focusNode: viewModel.emailFN,
            nextFocusNode: viewModel.countryFN,
          ),
          SizedBox(height: 20.0),
          TextFormBuilder(  //  Champ : Pays
            enabled: !viewModel.loading,
            prefix: Ionicons.pin_outline,  //icône localisation
            hintText: "Country",
            textInputAction: TextInputAction.next,
            validateFunction: Validations.validateName,
            onSaved: (String val) {
              viewModel.setCountry(val);
            },
            focusNode: viewModel.countryFN,
            nextFocusNode: viewModel.passFN,
          ),
          SizedBox(height: 20.0),
          PasswordFormBuilder(  //  Champ : Mot de passe
            enabled: !viewModel.loading,
            prefix: Ionicons.lock_closed_outline, //icône cadenas fermé
            suffix: Ionicons.eye_outline,   //  icône œil pour afficher/masquer le mot de pass
            hintText: "Password",
            textInputAction: TextInputAction.next,
            validateFunction: Validations.validatePassword,
            obscureText: true, // cache le texte
            onSaved: (String val) {
              viewModel.setPassword(val);
            },
            focusNode: viewModel.passFN,
            nextFocusNode: viewModel.cPassFN,
          ),
          SizedBox(height: 20.0),
          PasswordFormBuilder(  // Champ : Confirmation du mot de passe
            enabled: !viewModel.loading,
            prefix: Ionicons.lock_open_outline,
            hintText: "Confirm Password",
            textInputAction: TextInputAction.done,
            validateFunction: Validations.validatePassword,
            submitAction: () => viewModel.register(context), // exécute la fonction d'inscription
            obscureText: true,
            onSaved: (String val) {
              viewModel.setConfirmPass(val);
            },
            focusNode: viewModel.cPassFN,
          ),
          SizedBox(height: 25.0),
          Container( // Bouton "Sign Up"
            height: 45.0,
            width: 180.0,
            child: ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).colorScheme.secondary),
              ),
              child: Text(
                'sign up'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => viewModel.register(context),       // Action au clic : appel à la méthode register() du ViewModel
            ),
          ),
        ],
      ),
    );
  }
}
