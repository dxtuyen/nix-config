{ ... }:

# Bộ gõ tiếng Việt: Fcitx5 + Bamboo engine (fcitx5-bamboo — port chính thức
# của BambooEngine sang fcitx5, dùng bamboo-core giống ibus-bamboo).
# LƯU Ý: tên trong profile phải là "bamboo" CHỮ THƯỜNG — fcitx5 đặt uniqueName
# theo tên file inputmethod/bamboo.conf của addon và tra profile phân biệt
# hoa/thường (viết "Bamboo" hoa sẽ bị loại: "Group Item ... is not valid").
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
    # Các option khớp với BambooConfig trong src/bambooconfig.h của fcitx5-bamboo.
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
