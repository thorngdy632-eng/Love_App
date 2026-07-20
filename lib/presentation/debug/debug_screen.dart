import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: const Color(0xFFE8547C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(label: 'Firebase Auth'),
          _Row(label: 'Signed in', value: '${user != null}'),
          if (user != null) ...[
            _Row(label: 'UID', value: user.uid),
            _Row(label: 'Email', value: user.email ?? '(none)'),
            _Row(label: 'Email verified', value: user.emailVerified.toString()),
            _Row(label: 'Provider', value: user.providerData.first.providerId),
          ],
          const SizedBox(height: 16),
          _Section(label: 'Firestore Persistence'),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .limit(1)
                .get(const GetOptions(source: Source.server)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _Row(label: 'Server read test', value: 'checking...');
              }
              if (snapshot.hasError) {
                return _Row(label: 'Server read test', value: 'ERROR: ${snapshot.error}', valueColor: Colors.red);
              }
              return _Row(label: 'Server read test', value: 'OK (${snapshot.data!.docs.length} doc(s))', valueColor: Colors.green);
            },
          ),
          const SizedBox(height: 16),
          _Section(label: 'App Config'),
          _Row(label: 'Authorized users', value: '${AppConstants.authorizedUsersByEmail.length}'),
          _Row(label: 'Start date', value: '${AppConstants.relationshipStartDate}'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8547C),
          fontFamily: 'KantumruyPro',
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'KantumruyPro',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'KantumruyPro',
                fontSize: 14,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
