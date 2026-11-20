{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    services.onepassword-secrets = {
      enable = true;
      tokenFile = "/etc/op-token";
      secrets = {
        hydraOidcClientSecret = {
          reference = "op://Secrets/Hydra OIDC/client secret";
          path = "/var/lib/hydra/secrets/puppy-id-client-secret";
          group = "hydra";
          mode = "0640";
        };
      };
    };

    nix.settings.allow-import-from-derivation = true;

    services.hydra = {
      enable = true;
      # Caddy reaches the host through Docker's gateway, not loopback.
      listenHost = "0.0.0.0";
      port = 3000;
      hydraURL = "https://hydra.szpunar.cloud"; # externally visible URL
      notificationSender = "hydra@szpunar.cloud"; # e-mail of Hydra service
      # you will probably also want this, otherwise *everything* will be built from scratch
      useSubstitutes = true;
      extraConfig = ''
        allow_import_from_derivation = true
        <oidc>
          <provider puppy-id>
            display_name = "Puppy ID"
            discovery_url = "https://auth.szpunar.cloud/.well-known/openid-configuration"
            client_id = "acebe53e-437a-46b5-8fb1-43a99f3aedbc"
            client_secret_file = "/var/lib/hydra/secrets/puppy-id-client-secret"
            role_claim = "groups"
            <role_mapping>
              lan = admin
              hydra-admins = admin
              hydra-builders = create-projects
              hydra-builders = eval-jobset
            </role_mapping>
          </provider>
        </oidc>
      '';
    };

    host.caddyDomains = ["https://hydra.szpunar.cloud"];

    # Allow container-to-host access without exposing Hydra on public interfaces.
    networking.firewall.interfaces."br+".allowedTCPPorts = [3000];

    virtualisation.arion.projects.magicplank-caddy.settings.services.caddy.service.extra_hosts = [
      "host.docker.internal:host-gateway"
    ];

    nix.buildMachines = [
      {
        hostName = "localhost";
        protocol = null;
        system = "x86_64-linux";
        supportedFeatures = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "benchmark"
        ];
        maxJobs = 12;
      }
    ];
  };
}
