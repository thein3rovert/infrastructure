{ self, ... }:
{
  age = {
    # MANUAL: generate with `ssh-keygen -t ed25519 -f ~/.ssh/thein3rovert_forgejo_runner`
    # then re-encrypt forgejo/runner/forgejo-runner-secret.age for the new
    # pubkey in the secret-vault repo (see hosts/runner/secret.nix).
    identityPaths = [
      "/home/thein3rovert/.ssh/thein3rovert_forgejo_runner"
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
