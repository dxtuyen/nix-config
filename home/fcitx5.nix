{ ... }:

{
  xdg.configFile = {
    "fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=unikey
      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=
      [Groups/0/Items/1]
      Name=unikey
      Layout=
      [GroupOrder]
      0=Default
    '';
    "fcitx5/conf/unikey.conf".text = ''
      [Config]
      InputMethod=0
      OutputCharset=0
      SpellCheck=True
      Macro=True
      ProcessWAtBegin=True
      AutoNonVnRestore=True
      ModernStyle=False
      FreeMarking=True
      SurroundingText=True
      ModifySurroundingText=False
      DisplayUnderline=True
    '';
  };
}