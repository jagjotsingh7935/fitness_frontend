import 'package:flutter/material.dart';

class TrainerProfilePage extends StatelessWidget {
  const TrainerProfilePage({super.key});

  // Dummy data for consistency with dashboard
  final String _trainerName = 'Alex Morgan';
  final String _specialization = 'Senior Strength & Conditioning Coach';
  final String _email = 'alex.morgan@fitpulse.com';
  final String _phone = '+91 98765 43210';
  final String _bio = 'Passionate about helping people achieve their fitness goals through science-based training and nutrition. 8+ years of experience in the industry specializing in body transformations and functional movement.';
  final List<String> _categories = const ['Strength', 'HIIT', 'Mobility', 'Nutrition'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFE94560)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),
            
            // Statistics Cards
            _buildStatsSection(),
            const SizedBox(height: 32),
            
            // About Section
            _buildAboutSection(),
            const SizedBox(height: 24),
            
            // Account Actions
            _buildAccountActions(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE94560).withOpacity(0.5), width: 3),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFF1A1A1A),
                child: Text(
                  _trainerName.isNotEmpty ? _trainerName[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: Color(0xFFE94560),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE94560),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _trainerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _specialization,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatCard('Clients', '24', Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Rating', '4.9', Colors.amber),
        const SizedBox(width: 12),
        _buildStatCard('Yrs Exp', '8+', const Color(0xFFE94560)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            _bio,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Specializations',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _categories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE94560).withOpacity(0.2)),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(color: Color(0xFFE94560), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildContactRow(Icons.email_outlined, _email),
          const SizedBox(height: 16),
          _buildContactRow(Icons.phone_outlined, _phone),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE94560)),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Account Settings',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildActionTile(Icons.person_outline, 'Edit Profile', () {}),
              _buildDivider(),
              _buildActionTile(Icons.notifications_none_rounded, 'Notifications', () {}),
              _buildDivider(),
              _buildActionTile(Icons.lock_outline_rounded, 'Privacy & Security', () {}),
              _buildDivider(),
              _buildActionTile(Icons.logout_rounded, 'Logout', () {}, isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : const Color(0xFFE94560)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFFE94560),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 20,
      endIndent: 20,
    );
  }
}