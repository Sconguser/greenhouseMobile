import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

enum AuthMode { signIn, signUp }

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
        Text(" / "),
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

class SignInForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            key: _emailFieldKey,
            name: 'signInEmail',
            decoration: InputDecoration(
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
            decoration: InputDecoration(
              hintText: 'Password',
            ),
            validator: FormBuilderValidators.required(
                errorText: "This field cannot be empty"),
            obscureText: true,
          ),
          ElevatedButton(
              onPressed: () {
                print(_emailFieldKey.currentState?.value);
              },
              child: Text("sign in"))
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
            decoration: InputDecoration(
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
            decoration: InputDecoration(
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
            decoration: InputDecoration(
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
            decoration: InputDecoration(
              hintText: 'Confirm password',
            ),

            //TODO: to nie dziala, do poprawy
            validator: FormBuilderValidators.equal(
                _passwordFieldKey.currentState?.value ?? '',
                errorText: "Passwords must match"),
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          ElevatedButton(
              onPressed: () {
                print(_emailFieldKey.currentState?.value);
                _formKey.currentState?.validate();
              },
              child: Text("sign up"))
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
                  onSignIn: () {},
                )
              : SignUpForm(
                  onSignUp: () {},
                ),
        ),
      ],
    );
  }
}
