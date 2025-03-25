import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:maker_greenhouse/providers/auth_notifier.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/views/error/error_view.dart';

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
            "Sign In",
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
            "Sign Up",
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
            decoration: const InputDecoration(
              hintText: 'Username',
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: "This field cannot be empty"),
              ],
            ),
          ),
          FormBuilderTextField(
            key: passwordFieldKey,
            name: "signInPassword",
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
            validator: FormBuilderValidators.required(
                errorText: "This field cannot be empty"),
            obscureText: true,
          ),
          const SizedBox(
            height: 10,
          ),
          AuthButton(formKey: _formKey, onPressed: onSignIn, text: "sign in"),
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
      return ErrorScreen(
          error: error,
          onRetry: () {
            ref.invalidate(authNotifierProvider);
          });
    }, loading: () {
      return LoadingIndicatorWidget();
    });
  }
}

class SignUpForm extends StatelessWidget {
  final Future<void> Function() onSignUp;
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderFieldState> passwordFieldKey;
  GlobalKey<FormBuilderFieldState> passwordConfirmationFieldKey;
  GlobalKey<FormBuilderFieldState> usernameFieldKey;

  SignUpForm({
    Key? key,
    required this.onSignUp,
    required this.passwordFieldKey,
    required this.passwordConfirmationFieldKey,
    required this.usernameFieldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: usernameFieldKey,
            name: 'signUpUsername',
            decoration: const InputDecoration(
              hintText: 'Username',
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: "This field cannot be empty"),
              ],
            ),
          ),
          FormBuilderTextField(
            key: passwordFieldKey,
            name: "signUpPassword",
            initialValue: "",
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.required(
                    errorText: "This field cannot be empty"),
                FormBuilderValidators.max(
                  20,
                  errorText: "Password can have up to 20 characters",
                ),
                FormBuilderValidators.min(
                  6,
                  errorText: "Password needs to be at least 6 characters long",
                ),
              ],
            ),
            obscureText: true,
          ),
          FormBuilderTextField(
            key: passwordConfirmationFieldKey,
            name: "signUpPasswordConfirmation",
            initialValue: "",
            decoration: const InputDecoration(
              hintText: 'Confirm password',
            ),

            //TODO: to nie dziala, do poprawy
            validator: FormBuilderValidators.required(
                errorText:
                    "Passwords must match // this does not work correctly"),
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(
            height: 10,
          ),
          AuthButton(formKey: _formKey, onPressed: onSignUp, text: "sign up"),
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Column(
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
                  onSignUp: () async {},
                ),
        ),
      ],
    );
  }
}
