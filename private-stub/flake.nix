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
          hostname = "personal-macbook";
        };
        nuc = {
          username = "user";
          hostname = "personal-nuc";
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
          hostname = "work-macbook";
        };
        dev = {
          username = "user";
          hostname = "work-dev";
          address = "";
        };
      };
    };
  };
}
