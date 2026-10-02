{ ... }:

# Vietnamese input: Fcitx5 + Bamboo engine (fcitx5-bamboo).
# The name in the profile must be lowercase "bamboo" — fcitx5 looks it up
# case-sensitively; "Bamboo" with a capital B will be rejected.
{
  xdg.configFile = {
    "fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=bamboo
      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=
      [Groups/0/Items/1]
      Name=bamboo
      Layout=
      [GroupOrder]
      0=Default
    '';
    # Matches BambooConfig in src/bambooconfig.h of fcitx5-bamboo.
    "fcitx5/conf/bamboo.conf".text = ''
      InputMethod=Telex
      OutputCharset=Unicode
      SpellCheck=True
      Macro=True
      AutoNonVnRestore=True
      ModernStyle=False
      FreeMarking=True
      DisplayUnderline=True
    '';
  };
}
