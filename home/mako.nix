{ ... }:

{
  services.mako = {
    enable = true;
    settings = {
      margin = "35,20,20,20";
      default-timeout = 5000;
      "app-name=quick-lang".default-timeout = 7000;
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=power-profiles".default-timeout = 2000;
    };
  };
}
