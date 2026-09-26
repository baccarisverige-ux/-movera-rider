import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/auth/presentation/create_acc.dart';
import 'package:movera_rider/features/auth/presentation/sign_in_phone.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key, this.controller});

  final AuthController? controller;

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late final AuthController _auth;
  String? _loadingProvider;

  @override
  void initState() {
    super.initState();
    _auth = widget.controller ?? AuthController();
  }

  Future<void> _signIn(String provider) async {
    if (_loadingProvider != null) return;
    setState(() => _loadingProvider = provider);
    try {
      await _auth.signIn(provider: provider);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        BottomToTopTransition(const Home()),
      );
    } catch (_) {
      if (!mounted) return;
      MoveraToast.show(context, 'Could not sign in with $provider.');
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Widget _loader() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            56.height,
            TextWidget(text: 'Sign in', fontSize: 24, fontWeight: fwExtraBold),
            9.height,
            TextWidget(
              text: 'Welcome back! Let’s get you riding',
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            50.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.mobile, height: ResSize.h * 24),
              ),
              centerContent: 'Continue with phone',
              onPressed: _loadingProvider == null
                  ? () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(
                          CreateAccount(controller: _auth),
                        ),
                      );
                    }
                  : null,
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
            16.height,
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.5),
                ),
                10.width,
                TextWidget(
                  text: 'or',
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
                10.width,
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.5),
                ),
              ],
            ),
            16.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.apple, height: ResSize.h * 24),
              ),
              centerContent: 'Continue with apple',
              onPressed: _loadingProvider == null ? () => _signIn('apple') : null,
              isLoading: _loadingProvider == 'apple',
              loader: _loader(),
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
            16.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.google, height: ResSize.h * 24),
              ),
              centerContent: 'Continue with Google',
              onPressed: _loadingProvider == null ? () => _signIn('google') : null,
              isLoading: _loadingProvider == 'google',
              loader: _loader(),
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHorizPadding,
            vertical: 8,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextWidget(
                text: 'Already have an account?',
                color: AppColor.subtitle,
                fontSize: 16,
                fontWeight: fwMedium,
              ),
              TextButton(
                onPressed: _loadingProvider == null
                    ? () {
                        Navigator.push(
                          context,
                          RightToLeftTransition(
                            SignInPhone(controller: _auth),
                          ),
                        );
                      }
                    : null,
                child: TextWidget(
                  text: 'Sign in',
                  color: AppColor.primary,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
