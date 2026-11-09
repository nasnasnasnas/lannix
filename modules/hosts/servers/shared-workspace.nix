{ ... }: {
  # Independent host-local workspaces; no synchronization or service-data move.
  # Setgid and default ACLs permit collaboration with ordinary umask 022.
  # Explicit 0600 files and moved-in permissions still need owner intervention.
  # Before activation, reject conflicting existing paths, symlinks or mounts;
  # never adopt/chown an unrelated existing workspace.
  flake.modules.nixos.server-shared-workspace = {
    users.groups.lannix-collab = { };
    users.users.magicbox.extraGroups = [ "lannix-collab" ];
    users.users.lavender.extraGroups = [ "lannix-collab" ];
    systemd.tmpfiles.rules = [
      "d /srv/shared 2770 root lannix-collab -"
      "a+ /srv/shared - - - - u::rwx,g::rwx,m::rwx,o::---,d:u::rwx,d:g::rwx,d:m::rwx,d:o::---"
    ];
  };
}
