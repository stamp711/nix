{
  flake.homeModules.personal = {
    my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
  };
}
