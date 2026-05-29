import 'package:flutter/material.dart';

import '../../state/signup_controller.dart';
import 'bio_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/option_grid.dart';

class GovernorateSignupScreen extends StatelessWidget {
  const GovernorateSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.location_on_outlined,
          title: 'محافظتك؟',
          subtitle: 'اختر محافظتك داخل العراق.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OptionGrid(
                values: iraqiGovernorates,
                selected: controller.governorate,
                onChanged: controller.setGovernorate,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'متابعة',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BioSignupScreen(controller: controller),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
