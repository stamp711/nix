{
  description = "Stub with dummy values for use without private SSH key access";
  inputs = { };
  outputs = _: {
    personal = {
      git = {
        name = "";
        email = "";
        signingKey = "";
      };
      hosts = {
        macbook = {
          username = "user";
          hostname = "host";
        };
        nuc = {
          username = "user";
          hostname = "host";
          address = "";
        };
      };
    };

    work = {
      git = {
        name = "";
        email = "";
        signingKey = "";
      };
      hosts = {
        macbook = {
          username = "user";
          hostname = "host";
        };
        dev = {
          username = "user";
          hostname = "host";
          address = "";
        };
      };
    };
  };
}
