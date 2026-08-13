{ ... }:

{
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      "app-name=quick-lang".default-timeout = 7000;
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
    };
  };
}