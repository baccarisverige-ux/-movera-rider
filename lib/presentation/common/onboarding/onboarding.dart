import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/models/onboarding.dart';
import 'package:riding_app/presentation/driver/auth/login/login.dart';
import 'package:riding_app/presentation/passenger/auth/login/login.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDriver;
  const OnboardingScreen({super.key, required this.isDriver});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  String currentTitle1 = '';
  String currentTitle2 = '';
  String currentSubtitle = '';
  int currentPageIndex = 0;

  List<OnBoardingModel> onBoardingList = [
    OnBoardingModel(
      image: AppAssets.onboarding1,
      title1: 'Accept ',
      title2: 'rides with confidence',
      subTitle:
          "Get trip requests instantly and accept jobs that suit your availability. View pickup details, estimated fare, and distance before you start — all in one place.",
    ),
    OnBoardingModel(
      image: AppAssets.onboarding2,
      title1: 'Smart ',
      title2: 'navigation & live tracking',
      subTitle:
          "Use built-in GPS navigation to reach passengers efficiently. Trips are tracked in real time, ensuring safety, transparency, and accurate journey records.",
    ),
    OnBoardingModel(
      image: AppAssets.onboarding3,
      title1: 'Earn ',
      title2: '& Get Paid Securely',
      subTitle:
          "Track your earnings, bonuses, and trip history anytime. Get paid securely through verified payment methods with clear, transparent breakdowns.",
    ),
  ];
  @override
  void initState() {
    super.initState();
    currentTitle1 = onBoardingList[currentPageIndex].title1;
    currentTitle2 = onBoardingList[currentPageIndex].title2;
    currentSubtitle = onBoardingList[currentPageIndex].subTitle;
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isImageAnimate = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload images
    for (var item in onBoardingList) {
      precacheImage(AssetImage(item.image), context);
    }
  }

  bool isImageAnimate = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            55.height,
            Expanded(
              child: SizedBox(
                child: Stack(
                  children: [
                    Expanded(
                      child: SizedBox(
                        child: PageView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          controller: controller,
                          itemCount: onBoardingList.length,
                          clipBehavior: Clip.none,
                          onPageChanged: (int index) {
                            setState(() {
                              currentPageIndex = index;
                              currentTitle1 = onBoardingList[index].title1;
                              currentTitle2 = onBoardingList[index].title2;
                              currentSubtitle = onBoardingList[index].subTitle;
                              isImageAnimate = true;
                            });
                            // Preload next image
                            if (index < onBoardingList.length - 1) {
                              precacheImage(
                                AssetImage(onBoardingList[index + 1].image),
                                context,
                              );
                            }
                          },
                          itemBuilder: (_, index) {
                            return SizedBox(
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: ResSize.h * 50,
                                        left: ResSize.w * 30,
                                        right: ResSize.w * 30,
                                        bottom: index == 2
                                            ? ResSize.h * 65
                                            : ResSize.h * 20,
                                      ),
                                      child: SizedBox(
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            opacity: isImageAnimate ? 1.0 : 0.0,
                                            child: Image.asset(
                                              onBoardingList[index].image,
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    currentPageIndex == 2
                        ? SizedBox()
                        : Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: ResSize.w * 20),
                              child: CustomButton(
                                centerContent: "Skip",
                                onPressed: () {
                                  widget.isDriver
                                      ? Navigator.pushReplacement(
                                          context,
                                          BottomToTopTransition(DriverLogin()),
                                        )
                                      : Navigator.pushReplacement(
                                          context,
                                          BottomToTopTransition(
                                            PassengerLogin(),
                                          ),
                                        );
                                },
                                borderRadius: 50,
                                borderColor: AppColor.primary,
                                btncolor: Colors.transparent,
                                borderwidth: 1,
                                height: ResSize.h * 40,
                                width: ResSize.h * 86,
                                textColor: AppColor.primary,
                              ),
                            ),
                          ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 0,
                          left: ResSize.w * 20,
                        ),
                        child: Image.asset(
                          AppAssets.yellowDot,
                          height: ResSize.h * 12,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 0,
                          right: ResSize.w * 20,
                        ),
                        child: Image.asset(
                          AppAssets.blackDot,
                          height: ResSize.h * 12,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: ResSize.w * 20),
                        child: Image.asset(
                          AppAssets.blackDot,
                          height: ResSize.h * 12,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: const Offset(0, 80),
                        child: Image.asset(
                          AppAssets.onboardGreyDot,
                          height: ResSize.h * 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 20,
                  vertical: ResSize.h * 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currentTitle1,
                            style: GoogleFonts.poppins(
                              color: AppColor.title,
                              fontSize: ResSize.setSp(32),
                              fontWeight: fwSemiBold,
                            ),
                          ),
                          TextSpan(
                            text: currentTitle2,
                            style: GoogleFonts.poppins(
                              color: AppColor.title,
                              fontSize: ResSize.setSp(32),
                              fontWeight: fwNormal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    2.height,
                    TextWidget(
                      text: currentSubtitle,
                      color: AppColor.title,
                      fontSize: ResSize.setSp(14),
                      fontWeight: fwNormal,
                      textAlign: TextAlign.start,
                    ),
                    25.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(AppAssets.blackDot, height: ResSize.h * 12),
                        Transform.translate(
                          offset: const Offset(0, 20),
                          child: Image.asset(
                            AppAssets.yellowDot,
                            height: ResSize.h * 12,
                          ),
                        ),
                      ],
                    ),
                    25.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: SmoothPageIndicator(
                            controller: controller,
                            count: onBoardingList.length,
                            effect: WormEffect(
                              dotHeight: 18,
                              dotWidth: 18,
                              activeDotColor: AppColor.primary,
                              dotColor: const Color(0xffDDDDDD),
                            ),
                            onDotClicked: (index) {},
                          ),
                        ),
                      ],
                    ),
                    20.height,
                    CustomButton(
                      centerContent: "Next",
                      onPressed: currentPageIndex == 2
                          ? () {
                              widget.isDriver
                                  ? Navigator.pushReplacement(
                                      context,
                                      BottomToTopTransition(DriverLogin()),
                                    )
                                  : Navigator.pushReplacement(
                                      context,
                                      BottomToTopTransition(PassengerLogin()),
                                    );
                            }
                          : () {
                              controller.animateToPage(
                                currentPageIndex + 1,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.linearToEaseOut,
                              );
                              isImageAnimate = false;
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
