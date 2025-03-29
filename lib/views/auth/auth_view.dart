import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:maker_greenhouse/providers/auth_notifier.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/providers/routes.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/views/error/error_view.dart';

import '../../generated/l10n.dart';

enum AuthMode { signIn, signUp }

final loadingState = StateProvider<bool>((ref) {
  return false;
});

class AuthModeChooser extends StatelessWidget {
  final AuthMode authMode;
  final ValueChanged<AuthMode> onModeChanged;

  const AuthModeChooser({
    Key? key,
    required this.authMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => onModeChanged(AuthMode.signIn),
          child: Text(
            S.of(context).authSignIn,
            style: TextStyle(
              fontWeight: authMode == AuthMode.signIn
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: authMode == AuthMode.signIn ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        const Text(" / "),
        TextButton(
          onPressed: () => onModeChanged(AuthMode.signUp),
          child: Text(
            S.of(context).authSignUp,
            style: TextStyle(
              fontWeight: authMode == AuthMode.signUp
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: authMode == AuthMode.signUp ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class SignInForm extends ConsumerWidget {
  final bool staySignedIn;
  final ValueChanged<bool> onStaySignedInChanged;
  final Future<void> Function() onSignIn;
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderFieldState> usernameFieldKey;
  final GlobalKey<FormBuilderFieldState> passwordFieldKey;

  SignInForm({
    Key? key,
    required this.staySignedIn,
    required this.onStaySignedInChanged,
    required this.onSignIn,
    required this.usernameFieldKey,
    required this.passwordFieldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: usernameFieldKey,
            name: 'signInUsername',
            decoration: InputDecoration(
              hintText: S.of(context).authUsername,
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: S.of(context).authThisFieldCannotBeEmpty),
              ],
            ),
          ),
          FormBuilderTextField(
            key: passwordFieldKey,
            name: "signInPassword",
            decoration: InputDecoration(
              hintText: S.of(context).authPassword,
            ),
            validator: FormBuilderValidators.required(
                errorText: S.of(context).authThisFieldCannotBeEmpty),
            obscureText: true,
          ),
          const SizedBox(
            height: 10,
          ),
          AuthButton(
              formKey: _formKey,
              onPressed: onSignIn,
              text: S.of(context).authSignIn),
        ],
      ),
    );
  }
}

class AuthButton extends ConsumerWidget {
  const AuthButton(
      {super.key,
      required GlobalKey<FormBuilderState> formKey,
      required this.onPressed,
      required this.text})
      : _formKey = formKey;

  final GlobalKey<FormBuilderState> _formKey;
  final Future<void> Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double height = MediaQuery.of(context).size.height;
    final authState = ref.watch(authNotifierProvider);
    return authState.when(data: (_) {
      return ElevatedButton(
        onPressed: () {
          _formKey.currentState?.validate();
          if (_formKey.currentState?.isValid == true) {
            onPressed();
          }
        },
        child: Text(text),
      );
    }, error: (error, stackTrace) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              16, // Add keyboard height + extra spacing
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ErrorScreen(
            error: error,
            onRetry: () => ref.invalidate(authNotifierProvider),
          ),
        ),
      );
    }, loading: () {
      return LoadingIndicatorWidget();
    });
  }
}

class SignUpForm extends StatelessWidget {
  final Future<void> Function() onSignUp;
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderFieldState> passwordFieldKey;
  final GlobalKey<FormBuilderFieldState> passwordConfirmationFieldKey;
  final GlobalKey<FormBuilderFieldState> usernameFieldKey;

  SignUpForm({
    super.key,
    required this.onSignUp,
    required this.passwordFieldKey,
    required this.passwordConfirmationFieldKey,
    required this.usernameFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    int maxPasswordsLength = 20;
    int minPasswordLength = 6;
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: usernameFieldKey,
            name: 'signUpUsername',
            decoration: InputDecoration(
              hintText: S.of(context).authUsername,
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: S.of(context).authThisFieldCannotBeEmpty),
              ],
            ),
          ),
          FormBuilderTextField(
            key: passwordFieldKey,
            name: "signUpPassword",
            initialValue: "",
            decoration: InputDecoration(
              hintText: S.of(context).authPassword,
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: S.of(context).authThisFieldCannotBeEmpty),
                FormBuilderValidators.max(
                  maxPasswordsLength,
                  errorText:
                      S.of(context).authPasswordTooLong(maxPasswordsLength),
                ),
                FormBuilderValidators.min(
                  minPasswordLength,
                  errorText:
                      S.of(context).authPasswordTooShort(minPasswordLength),
                ),
              ],
            ),
            obscureText: true,
          ),
          FormBuilderTextField(
            key: passwordConfirmationFieldKey,
            name: "signUpPasswordConfirmation",
            initialValue: "",
            decoration: InputDecoration(
              hintText: S.of(context).authPasswordConfirmation,
            ),

            //TODO: to nie dziala, do poprawy
            validator: FormBuilderValidators.required(
                errorText: S.of(context).authPasswordsDoNotMatch),
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(
            height: 10,
          ),
          AuthButton(
              formKey: _formKey,
              onPressed: onSignUp,
              text: S.of(context).authSignUp),
        ],
      ),
    );
  }
}

class AuthView extends ConsumerStatefulWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  AuthMode authMode = AuthMode.signIn;

  void toggleAuthMode(AuthMode mode) {
    setState(() {
      authMode = mode;
    });
  }

  bool _staySignedIn = false;
  final _signInUsernameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _signInPasswordFieldKey = GlobalKey<FormBuilderFieldState>();
  final _signUpUsernameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _signUpPasswordFieldKey = GlobalKey<FormBuilderFieldState>();
  final _signUpPasswordConfirmationFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    ref.watch(languageNotifierProvider);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      ///TODO: to be used in the future
      // floatingActionButton: TextButton(
      //   child: Text(S.of(context).bottomNavBarSettings),
      //   onPressed: () {
      //     ref.read(goRouterProvider).go(AppRoutes.settingsUnauthorized.path);
      //   },
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthModeChooser(authMode: authMode, onModeChanged: toggleAuthMode),
          Container(
            width: width * 0.6,
            child: authMode == AuthMode.signIn
                ? SignInForm(
                    usernameFieldKey: _signInUsernameFieldKey,
                    passwordFieldKey: _signInPasswordFieldKey,
                    staySignedIn: _staySignedIn,
                    onStaySignedInChanged: (value) {
                      setState(() {
                        _staySignedIn = value;
                      });
                    },
                    onSignIn: () async {
                      ref.read(authNotifierProvider.notifier).login(
                          _signInUsernameFieldKey.currentState?.value,
                          _signInPasswordFieldKey.currentState?.value);
                    },
                  )
                : SignUpForm(
                    usernameFieldKey: _signUpUsernameFieldKey,
                    passwordFieldKey: _signUpPasswordFieldKey,
                    passwordConfirmationFieldKey:
                        _signUpPasswordConfirmationFieldKey,
                    onSignUp: () async {
                      ref.read(authNotifierProvider.notifier).signUp(
                          _signUpUsernameFieldKey.currentState?.value,
                          _signUpPasswordFieldKey.currentState?.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
