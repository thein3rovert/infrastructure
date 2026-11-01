{ self, ... }:
{
  age = {
    # Reuses the existing runner keypair (~/.ssh/thein3rovert_runner), which
    # is already a recipient of forgejo-runner-secret.age in secret-vault.
    identityPaths = [
      "/home/thein3rovert/.ssh/thein3rovert_runner"
    ];
    secrets = {
      tailscale = {
        file = "${self.inputs.secrets}/tailscale/shared/tailscale-auth.age";
        path = "/home/thein3rovert/.secrets/tailscale-auth";
      };
      forgejo-runner = {
        file = "${self.inputs.secrets}/forgejo/runner/forgejo-runner-secret.age";
        path = "/home/thein3rovert/.secrets/forgejo-runner-secret";
      };
    };
  };
}
