/// Remote-config driven force-update policy for a single platform.
class ForceUpdateConfig {
  const ForceUpdateConfig({
    required this.required,
    required this.minimumBuild,
    required this.storeUrl,
  });

  final bool required;
  final int minimumBuild;
  final String storeUrl;

  static const disabled = ForceUpdateConfig(
    required: false,
    minimumBuild: 0,
    storeUrl: '',
  );
}
