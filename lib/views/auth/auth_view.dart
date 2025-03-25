import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';

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
  final VoidCallback onSignIn;
  final _formKey = GlobalKey<FormBuilderState>();
  final _emailFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordFieldKey = GlobalKey<FormBuilderFieldState>();

  SignInForm({
    Key? key,
    required this.staySignedIn,
    required this.onStaySignedInChanged,
    required this.onSignIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: _emailFieldKey,
            name: 'signInEmail',
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.email(errorText: "Invalid email format"),
                FormBuilderValidators.required(
                    errorText: "This field cannot be empty"),
              ],
            ),
          ),
          FormBuilderTextField(
            key: _passwordFieldKey,
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
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(loadingState);
              return authState == false
                  ? ElevatedButton(
                      onPressed: () {
                        _formKey.currentState?.validate();
                        if (_formKey.currentState?.isValid == true) {
                          onSignIn();
                        }
                      },
                      child: const Text("sign in"))
                  : const LoadingIndicatorWidget();
            },
          )
        ],
      ),
    );
  }
}

class SignUpForm extends StatelessWidget {
  final VoidCallback onSignUp;
  final _formKey = GlobalKey<FormBuilderState>();
  final _emailFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordConfirmationFieldKey = GlobalKey<FormBuilderFieldState>();
  final _usernameFieldKey = GlobalKey<FormBuilderFieldState>();

  SignUpForm({
    Key? key,
    required this.onSignUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: _usernameFieldKey,
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
            key: _emailFieldKey,
            name: 'signUpEmail',
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.email(errorText: "Invalid email format"),
                FormBuilderValidators.required(
                    errorText: "This field cannot be empty"),
              ],
            ),
          ),
          FormBuilderTextField(
            key: _passwordFieldKey,
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
            key: _passwordConfirmationFieldKey,
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
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(loadingState);
              return authState == false
                  ? ElevatedButton(
                      onPressed: () {
                        _formKey.currentState?.validate();
                        if (_formKey.currentState?.isValid == true) {
                          onSignUp();
                        }
                      },
                      child: const Text("sign up"))
                  : const LoadingIndicatorWidget();
            },
          )
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
                  staySignedIn: _staySignedIn,
                  onStaySignedInChanged: (value) {
                    setState(() {
                      _staySignedIn = value;
                    });
                  },
                  onSignIn: () {
                    ref.read(loadingState.notifier).state = true;
                  },
                )
              : SignUpForm(
                  onSignUp: () {
                    ref.read(loadingState.notifier).state = true;
                  },
                ),
        ),
      ],
    );
  }
}
