{
  description = "Stub for use without private SSH key access";
  inputs = { };
  outputs = _: {
    homeModules = {
      _all = [ ];
      personal._all = [ ];
      work = {
        _all = [ ];
        shared._all = [ ];
        devbox._all = [ ];
      };
    };

    personal.hosts = {
      macbook = {
        username = "user";
        hostname = "personal-macbook";
      };
      nuc = {
        username = "user";
        hostname = "personal-nuc";
        address = "";
      };
    };
    work.hosts = {
      macbook = {
        username = "user";
        hostname = "work-macbook";
      };
      dev = {
        username = "user";
        hostname = "work-dev";
        address = "";
      };
    };
  };
}
