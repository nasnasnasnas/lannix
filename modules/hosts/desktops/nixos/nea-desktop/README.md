# nea-desktop

The native NixOS configuration for Nea's AMD desktop, migrated from `nasnix`.
The repository's `mkNixos` helper includes the Lix module for both the Nix CLI
and daemon. Disk UUIDs and the original NixOS/Home Manager state versions are
preserved.

## Rebuild

From `/home/nea/lannix`:

```sh
sudo nixos-rebuild switch --flake .#nea-desktop
```

Scheduled upgrades and the Fish alias `lannix-rebuild` use this checkout.
After the first switch, log out and back in to start Noctalia v5 and pick up the
new application/session environment. Reboot to use the new CachyOS kernel.

Verify Lix after switching:

```sh
nix --version
systemctl cat nix-daemon.service
```

The CLI should identify itself as Lix and the daemon's `ExecStart` should point
to a `lix` store path.

## Applications and desktop

- Noctalia v5 uses `noctalia/config.toml` and `noctalia msg` IPC. Its configuration
  is validated during the build. Niri's monitor layout, mouse settings, and
  shortcuts are migrated here; touchpads use acceleration `0.3` and natural
  scrolling.
- Noctalia Greeter replaces COSMIC and defaults to the Niri session. Desktop
  appearance is synchronized with `noctalia msg greeter-sync`; automatic sync is
  enabled for future palette, wallpaper, and font changes.
- Control Center floats at the top right with the soft panel style (80% opaque
  background and approximately 88% opaque cards), independently of the glass bar.
- The Noctalia dock mimics the macOS Dock: always visible at the bottom with
  reserved space, floating with convex corners and a hairline border, black
  running-app dots, and GNOME Files pinned first in place of Finder. Icons are
  60 px with no extra item spacing; Noctalia always pads each icon by 6 px per
  side. Hold a pinned icon, then drag it to reorder; Noctalia saves the new
  order as a runtime override that takes precedence over `dock.pinned` here.
- Workspace pills use fixed macOS dark grays (`#636366` focused, `#48484A`
  occupied, `#3A3A3C` empty) instead of palette colors, without a hover tint.
  Noctalia picks pill text color by fill luminance; these grays keep it white.
- Apple's San Francisco and New York fonts (`modules/apps/apple-fonts.nix`,
  fetched from Apple's developer site) are the fontconfig defaults: SF Pro
  Text for sans-serif, New York for serif, and SF Mono for monospace. GTK
  (`gtk.font`, GSettings document/monospace fonts), qt6ct, Noctalia
  (`shell.font_family`, which the greeter syncs), and Ghostty name them
  explicitly. Apple publishes the installers at unversioned URLs, so a new
  release breaks the pinned hashes until they are updated. Apple's license
  only covers use on Apple platforms.
- GNOME Files (Nautilus) replaces Dolphin and opens folders by default. Its
  context menu has Ghostty's own "Open in Ghostty" action, loaded through
  nautilus-python (`NAUTILUS_4_EXTENSION_DIR`). Ghostty is installed only by
  Home Manager's `programs.ghostty`; a second copy in the system profile would
  load the extension twice.
- Applications use MacTahoe instead of Noctalia's generated colors:
  `mactahoe-gtk-theme` (`modules/apps/mactahoe-gtk-theme.nix`, light) for
  GTK 3 and GTK 4/libadwaita via Home Manager's `gtk` module, and
  `mactahoe-kde` (`modules/apps/mactahoe-kde.nix`) for Qt and KDE apps through
  the Kvantum style (`QT_STYLE_OVERRIDE=kvantum`, qt6ct style `kvantum`).
  Both are recolored from Tahoe blue to the lilac in
  `modules/apps/_mactahoe-accent.nix` (`#8A56D4`, the light-mode primary of
  Noctalia's Lilac AMOLED palette): the GTK build uses MacTahoe's `purple`
  variant with that color, and the Kvantum SVG/config and KDE color schemes
  have their blues mapped to lilac shades. Activation merges
  `MacTahoeLight.colors` into `kdeglobals` so KDE color roles match Kvantum.
  GTK window buttons sit on the left in macOS order. Noctalia keeps theming
  only Ghostty and Niri, and still syncs the GNOME `color-scheme` preference.
  Turning off Noctalia's GTK 3, GTK 4, and Qt templates gives up:
  - GTK and Qt colors generated from the Noctalia palette (Lilac AMOLED now),
    including palette and wallpaper changes reaching apps live. The lilac
    accent above is a fixed copy of today's primary.
  - The light/dark switch: Noctalia selected `adw-gtk3`/`adw-gtk3-dark`;
    MacTahoe-Light-purple and the light Kvantum theme are fixed here.
  - Community templates' app-specific GTK CSS extensions, which load only
    through the built-in GTK templates.
- Icons use the light `macOS27` theme from a private archive, packaged in
  `icons.nix` and applied to GTK (GSettings, `settings.ini`), qt6ct, and
  `kdeglobals`. It covers app, place, device, and MIME icons and inherits the
  rest from Adwaita, which is installed alongside it. Import the archive before
  building this host, then follow the CI source caching instructions below:

  ```sh
  nix-prefetch-url file://$HOME/Downloads/macOS27.tar.gz
  ```

  Apps without a `macOS27` icon fall back to their own hicolor icons.
- The top bar's left and right margins match Niri's 8 px window gaps.
- Noctalia carries two patches: `noctalia-translucent-tooltips.patch` makes
  tooltips follow `shell.panel.transparency_mode` with compositor blur, and
  `noctalia-dock-dot-color.patch` adds `dock.dot_color`. Both patches target
  the locked Noctalia source (`b096daa50f842c22332a04dbafd7d561d15825be`);
  the dock schema now lives in `config_schema_dock.cpp`. Tooltips use xdg popups, so the tooltip
  manager owns their background-effect protocol object and releases it before
  destroying the popup; blur is not a `PopupSurface` method.
- The community `vn1k/icons` plugin is enabled; Noctalia exports it on start.
  Open it with `noctalia msg panel-toggle vn1k/icons:manager`.
- Ghostty's terminal palette follows Noctalia; its window and tabs use light UI.
- Feishin is installed from nixpkgs-unstable.
- JetBrains Toolbox comes from nixpkgs-unstable; stable's 3.1.0.62320 archive
  is no longer available from JetBrains.
- Spotify comes from `Gerg-L/spicetify-nix` (`spicetify.nix`) with the
  Catppuccin theme in its light `latte` scheme; `pkgs.spotify` must not be
  added elsewhere. Spotify still draws its dark-UI overlays under Latte, so
  `spicetify-latte.css` (a spicetify snippet) removes them: headers drop the
  cover-art color and black fades and sit on the flat Latte base (the artist
  name gets a base-colored halo over its photo instead), cover art and row
  edges lose their shadows and fade masks, white-alpha tinted surfaces use the
  Latte text color, and white text set through variables or inline styles uses
  Latte's subtext. Rules that hardcode `color:#ffffffb3` are rewritten to
  `var(--text-subdued)` after `spicetify apply`, which is why the module's own
  install is disabled and an overridden `spicedSpotify` is installed instead.
  Several selectors target Spotify's generated names (`.before-scroll-node`,
  `main-*` classes); a Spotify update can stop them from matching, which shows
  up as dark overlays returning. The accent color is chosen in Spotify's
  settings page.
- Niri carries `reverse-overview-swipe.patch` so four fingers down opens the
  overview and four fingers up closes it. Two-finger scrolling and three-finger
  navigation keep their original directions. A compositor logout/login is
  required after installing or changing this patch.
- `amaanq/nirinit` (`nirinit.nix`) saves Niri's open windows every 5 minutes to
  `~/.local/share/nirinit/session.json` and reopens them on their workspaces
  and outputs at login. 1Password, Hex, and Noctalia's settings window are
  skipped because they start on their own. Delete the session file to start
  fresh. The user service is enabled for every user on this host.
  `lilac` uses the same module and save interval, skipping 1Password and
  Noctalia (it does not run Hex).
- Helium comes from `tomsch/helium-nix` and is the default HTTP/HTTPS/HTML browser.
  `programs.nix` adds libglvnd and the OpenGL driver directory to its
  `LD_LIBRARY_PATH`. Without them, ANGLE can't load `libEGL.so.1` and WebGL
  and GPU compositing are turned off.
- oh-my-pi comes from its upstream `can1357/oh-my-pi` flake, patched by
  `modules/apps/omp.nix` so it identifies as `opencode` during Figma MCP OAuth.
  Figma's dynamic client registration endpoint
  (`https://api.figma.com/v1/oauth/mcp/register`) returns 403 to every RFC 7591
  `client_name` outside its MCP catalog; `omp-opencode-client.patch` rewrites
  omp's `client_name` and MCP `clientInfo`, which is all Figma checks.
  Upstream excludes native addons from worker code-skew detection, including
  freshly extracted addons in standalone binaries; no local workaround is
  needed. JavaScript code-skew detection and install checks stay enabled.
  Update this input independently with `nix flake update omp`. Native Rust
  compilation belongs on the CI runner rather than the desktop.
- Tern is shared with `lilac` through `modules/apps/tern.nix`, which defines
  `packages.tern` and the common NixOS desktop integration. It uses
  `theoparis/nix-tern`, overridden to package the downloaded 0.9.16 beta and use
  Fish. Import the downloaded archive before building, then follow the CI
  source caching instructions below:

  ```sh
  nix-prefetch-url file://$HOME/Downloads/Tern-0.9.16-linux-x86_64.tar.gz
  ```

  The expected hash is pinned in `modules/apps/tern.nix`; the archive is not
  part of this repo. `nix build .#tern` builds the shared package without a
  system rebuild. Both hosts use the same pin, Fish override, WebKit/GIO TLS
  environment, runtime library fix, and desktop entry. `lilac` additionally
  defines its `tern-remote` user service, using that same package; its
  `niri-tern` keybinding helper uses the system-installed Tern. It waits for
  the new tab's prompt, then sends `exec /run/current-system/sw/bin/fish -l`
  to load Leah's configured Fish/Starship environment. Keep this workaround:
  the default tab shell did not load that environment, and passing Fish as
  an explicit launch command changes Tern's close-confirmation behavior.
  `lilac` no longer enables nix-ld: the package patches Tern's ELF interpreter
  and runtime library paths directly.
  Leah's Linux Fish initialization recovers a missing `NIRI_SOCKET` from the
  systemd user environment when its socket exists. Tern's daemon has the
  variable, but its new shells omit it; changing `tern-remote` ordering does
  not fix that. Existing shells need the variable exported manually or a
  fresh Fish shell after activating the Home Manager change.
- Graphical askpass is disabled for both SSH and Git. SSH uses
  `programs.ssh.enableAskPassword = false` and `SSH_ASKPASS_REQUIRE=never`;
  Git uses an empty `core.askPass` and `GIT_ASKPASS`, since Git otherwise
  falls back to `SSH_ASKPASS` without consulting `SSH_ASKPASS_REQUIRE`.
  New Fish shells clear inherited helpers too: a rebuild cannot update the
  environment of an already-running Niri or terminal daemon. In an existing
  Fish terminal, `set -gx GIT_ASKPASS ""; set -gx SSH_ASKPASS "";
  set -gx SSH_ASKPASS_REQUIRE never` applies the same policy immediately.
  Agent authentication and terminal prompts remain available; noninteractive
  commands fail without credentials instead of opening an X11 dialog.
- WinApps credentials remain local: activation preserves the existing config as
  a mode-0600 regular file before retiring the old Home Manager symlink.
- Existing unmanaged Home Manager files are saved with `.lannix-backup` suffixes
  during migration.

## CI source caching

CI already reads `https://attic.szpunar.cloud/lannix` and trusts its signing
key through `modules/flake/nix-cache/nix-cache.nix`. Local imports alone do not
populate that cache. Upload the pinned source archives explicitly: pushing
the finished Tern package does not include its build-time source archive.

The cache is intentionally public, including these download artifacts; Tern
still requires its own Stencil account sign-in.

1. Import the downloaded archives using the `nix-prefetch-url` commands above.
2. Install `attic-client` or enter a Nix shell containing it.
3. Log in to `https://attic.szpunar.cloud/` using an Attic client token with
   pull and push permission for `lannix` (the same kind of token as Forgejo's
   `ATTIC_TOKEN`, not the server's signing secret).

   If a client token needs to be generated, run this on magicplank:

   ```sh
   docker exec atticd atticadm -f /attic/server.toml make-token \
     --sub nea --validity 1y --pull lannix --push lannix
   ```

   On the desktop, this Bash command prompts without putting the token
   itself in shell history:

   ```sh
   bash -c 'read -rsp "Attic push token: " token; printf "\n"; attic login personal https://attic.szpunar.cloud/ "$token"'
   ```

4. Push both pinned source paths:

   ```sh
   attic push --no-closure personal:lannix \
     /nix/store/bggs36hwvx75hsd8kcazafd67ffvpxph-Tern-0.9.16-linux-x86_64.tar.gz \
     /nix/store/53f03jfyqldh2801kargkg2z9kl6wg7g-macOS27.tar.gz
   ```

   Here `personal` is the server name chosen during `attic login`. Repeat the
   upload when an archive pin changes. Retain the local downloads and GC roots
   as a backup if cache retention eventually removes an unused source.

   To cache the finished shared Tern package and its runtime closure as well:

   ```sh
   nix build .#tern --no-link --print-out-paths | xargs attic push personal:lannix
   ```

5. Retry CI. Its existing Attic push step caches successful build outputs;
   no runner SSH provisioning or new cache is needed.
