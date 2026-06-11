class AvatarUnlockConfig {
  final String name;
  final String src;
  final int unlockLevel;

  const AvatarUnlockConfig({
    required this.name,
    required this.src,
    required this.unlockLevel,
  });

  static const List<AvatarUnlockConfig> all = [
    AvatarUnlockConfig(
      name: 'Junior',
      src: 'assets/Junior_traveler.glb',
      unlockLevel: 1,
    ),
    AvatarUnlockConfig(
      name: 'Traveler',
      src: 'assets/traveler.glb',
      unlockLevel: 1,
    ),
    AvatarUnlockConfig(
      name: 'Adult Traveler',
      src: 'assets/adult_traveler.glb',
      unlockLevel: 6,
    ),
    AvatarUnlockConfig(
      name: 'Old Elf',
      src: 'assets/Old_elf_traveler.glb',
      unlockLevel: 10,
    ),
    AvatarUnlockConfig(
      name: 'Old Man',
      src: 'assets/old_man_traveler.glb',
      unlockLevel: 15,
    ),
  ];
}
