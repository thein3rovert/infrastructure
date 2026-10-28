{
  pkgs,
  lib,
  config,
  ...
}:
let

  if-postgresql-enable = lib.mkIf config.nixosSetup.services.postgresql.enable;
in
{

  options.nixosSetup.services.postgresql = {
    enable = lib.mkEnableOption "mysql Database";
  };
  config = if-postgresql-enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      package = pkgs.postgresql_17;
      extensions = with pkgs.postgresql17Packages; [
        pgvector
      ];
      authentication = ''
        # Make local host trust worthy
        local all all trust
        host all all ${config.homelab.ipAddresses.localhost.ip}/32 trust
        host all all ::1/128 trust

        host all all ${config.homelab.ipAddresses.podman0.ip}/16 trust
        host all all  ${config.homelab.ipAddresses.podman-web.ip}/16  trust

        # Authenticate with Tailscale IPs
        host all all  ${config.homelab.ipAddresses.bellamy.tailscaleIp}/32 md5
        host all all  ${config.homelab.ipAddresses.marcus.tailscaleIp}/32 md5
        host all all  ${config.homelab.ipAddresses.roan.tailscaleIp}/32 md5
      '';
      initialScript = pkgs.writeText "initialScript.sql" ''
        CREATE USER n8n WITH PASSWORD 'n8n';
        CREATE DATABASE n8n;
        GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
        ALTER DATABASE n8n OWNER to n8n;

        CREATE USER forgejo WITH PASSWORD 'forgejo';
        CREATE DATABASE forgejo OWNER forgejo;
        GRANT ALL PRIVILEGES ON DATABASE forgejo TO forgejo;

        CREATE USER kestra WITH PASSWORD 'kestra';
        CREATE DATABASE kestra OWNER kestra;
        GRANT ALL PRIVILEGES ON DATABASE kestra TO kestra;

        CREATE USER kaneo WITH PASSWORD 'kaneo';
        CREATE DATABASE kaneo OWNER kaneo;
        GRANT ALL PRIVILEGES ON DATABASE kaneo TO kaneo;
      '';
      # Monitoring login for Uptime Kuma. The role itself is declarative
      # here; the password is NOT in Nix — set once out-of-band and store
      # in Vault (secret/uptime-kuma). SELECT 1 probes only need CONNECT,
      # which databases grant to PUBLIC by default; the pg_hba host rules
      # above already permit md5 auth from the Kuma host (bellamy).
      ensureUsers = [
        {
          name = "kuma_monitor";
          ensureClauses.login = true;
        }
      ];
    };

    # Set up backup
    # Save under var/backup
    services.postgresqlBackup = {
      enable = true;
      startAt = "03:10:00";
      databases = [
        "n8n"
        "forgejo"
        "kestra"
        "kaneo"
      ];
    };

    networking.firewall.allowedTCPPorts = [ config.homelab.servicePorts.postgresql ];
  };
}
