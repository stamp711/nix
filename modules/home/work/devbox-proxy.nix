{
  description = "Work devbox proxy settings";

  # TODO: pull from private
  module = {
    home.sessionVariables = {
      http_proxy = "";
      https_proxy = "";
      HTTP_PROXY = "";
      HTTPS_PROXY = "";
      no_proxy = "localhost,127.0.0.1,.company.com";
      NO_PROXY = "localhost,127.0.0.1,.company.com";
    };
  };
}
