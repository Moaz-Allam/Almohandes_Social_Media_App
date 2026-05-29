import 'package:flutter/material.dart';

import '../../models/account_type.dart';
import '../../state/signup_controller.dart';
import 'governorate_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/option_grid.dart';

class SpecializationSignupScreen extends StatelessWidget {
  const SpecializationSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.engineering_outlined,
          title: controller.userType.specializationTitle,
          subtitle: controller.userType.specializationSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OptionGrid(
                values: controller.specializationOptions,
                selected: controller.specialization,
                onChanged: controller.setSpecialization,
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'متابعة',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GovernorateSignupScreen(controller: controller),
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
