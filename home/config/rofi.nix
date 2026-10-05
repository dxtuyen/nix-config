{ ... }:

{
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      drun-display-format: "{name}";
      font: "JetBrains Mono 11";
      location: 0;
      disable-history: false;
      hover-select: false;
      me-select-entry: "";
      me-accept-entry: "MousePrimary";
    }

    @theme "catppuccin-mocha"
  '';

  xdg.configFile."rofi/catppuccin-mocha.rasi".text = ''
    * {
      bg:                 #1e1e2eb3;
      bg-soft:            #181825;
      surface:            #313244;
      surface-hover:      #45475a;
      selected:           #585b70;
      fg:                 #cdd6f4;
      muted:              #a6adc8;
      blue:               #89b4fa;
      lavender:           #b4befe;
      red:                #f38ba8;
      background-color:   transparent;
      text-color:         @fg;
      margin:             0;
      padding:            0;
      spacing:            0;
    }

    window {
      width:              42%;
      transparency:       "real";
      border:             2px;
      border-color:       @blue;
      border-radius:      16px;
      background-color:   @bg;
    }

    mainbox {
      padding:            18px;
      spacing:            14px;
      background-color:   @bg;
      border-radius:      14px;
    }

    inputbar {
      padding:            13px 16px;
      spacing:            10px;
      border:             1px;
      border-color:       @surface;
      border-radius:      11px;
      background-color:   @bg-soft;
      children:           [ "prompt", "entry" ];
    }

    prompt {
      text-color:         @blue;
      font:               "JetBrains Mono Bold 11";
    }

    entry {
      placeholder:        "Search applications…";
      placeholder-color:  @muted;
      text-color:         @fg;
    }

    message {
      padding:            0 4px;
      background-color:   transparent;
    }

    textbox {
      text-color:         @muted;
      background-color:   transparent;
    }

    listview {
      columns:            1;
      lines:              8;
      fixed-height:       true;
      cycle:              true;
      scrollbar:          false;
      spacing:            5px;
      background-color:   transparent;
    }

    element {
      padding:            9px 12px;
      border-radius:      9px;
      background-color:   transparent;
      text-color:         @fg;
    }

    element normal.normal {
      text-color:         @fg;
    }

    element normal.active {
      text-color:         @lavender;
    }

    element normal.urgent {
      text-color:         @red;
    }

    element selected.normal {
      background-color:   @selected;
      text-color:         @fg;
    }

    element selected.active {
      background-color:   @selected;
      text-color:         @lavender;
    }

    element selected.urgent {
      background-color:   @selected;
      text-color:         @red;
    }

    element-icon {
      size:               26px;
      margin:             0 12px 0 0;
      background-color:   transparent;
    }

    element-text {
      vertical-align:     0.5;
      background-color:   transparent;
    }

    scrollbar {
      handle-width:       4px;
      border:             0;
      border-color:       @bg;
      background-color:   @bg;
      handle-color:       @surface-hover;
    }
  '';
}
