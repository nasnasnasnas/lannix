# Octelium + Cordium cluster

A 3-node HA k3s cluster (embedded etcd, all nodes are servers) over Tailscale,
hosting [Octelium](https://github.com/octelium/octelium) (zero-trust access
platform) and [Cordium](https://github.com/octelium/cordium) (sandbox platform
on top of Octelium). Long-term, the dockerized arion services migrate into it.

| host       | k3s                  | octelium labels         | IPs                                             |
| ---------- | -------------------- | ----------------------- | ----------------------------------------------- |
| remotebox  | server, cluster-init | controlplane, dataplane | ts 100.117.147.116, public 45.8.201.111         |
| magicplank | server (join)        | dataplane, cordium      | ts PLACEHOLDER-FILL-ME, public 107.219.61.126   |
| magicbox   | server (join)        | dataplane, cordium      | ts 100.83.201.118, no public IP                 |

Files:

- `octelium-node.nix` — shared module (`flake.modules.nixos.octelium-node`):
  k3s server, node labels, tailscale-only cluster ports, opnix token, CLIs.
- `datastores.nix` — Octelium's Postgres + Redis as declarative k3s manifests
  (`flake.modules.nixos.octelium-datastores`, imported by remotebox only);
  passwords bridged from 1Password into k8s Secrets at runtime.
- `octelium-resources.nix` — Octelium's own resources (Service/Policy/User/…)
  as nix attrsets under `octelium-cluster.resources`, converged with
  `octeliumctl apply` by a oneshot on remotebox (see below).
- `octelium-packages.nix` — `pkgs.{octelium,octeliumctl,octops,cordium}` from
  pinned release binaries. Bump = edit version + rehash
  (`nix store prefetch-file <url>`).
- `dns.nix` — `octelium.szpunar.cloud` + `*.octelium.szpunar.cloud` A records
  for the public dataplane IPs; apply via the usual pulumi DNS flow.
- per-host wiring: `modules/hosts/servers/<host>/cluster.nix`.

## Before first deploy

1. Fill the `PLACEHOLDER-FILL-ME` in `modules/hosts/servers/magicplank/cluster.nix`
   (`tailscale ip -4` on magicplank).
2. Create three 1Password items in the `Secrets` vault, each with a long
   random `password` field: `k3s Cluster Token` (read by all three nodes),
   `Octelium Postgres` and `Octelium Redis` (read by remotebox for the
   in-cluster datastores). `/etc/op-token` must already exist, as for the
   other opnix services.
3. Router port-forwards for magicplank: 443/tcp and 53820/udp → 107.219.61.126
   is its NAT'd public address; without forwards its DNS records serve dead
   traffic.

## Deploy order

remotebox first (cluster-init), then magicplank, then magicbox. Afterwards on
any node:

```sh
sudo kubectl get nodes            # expect 3 Ready
sudo kubectl get nodes --show-labels | grep octelium.com/node-mode
sudo kubectl get storageclass     # local-path (default) — required by Cordium
```

kubeconfig lives at `/etc/rancher/k3s/k3s.yaml`.

## Installing Octelium

Octelium needs Postgres + Redis; both are deployed declaratively by
`datastores.nix` into the `octelium` namespace (postgres.octelium.svc:5432,
redis.octelium.svc:6379) as soon as remotebox is up — check with
`kubectl get pods -n octelium`. The only remaining imperative step is the
bootstrap — verify the exact schema against the current Octelium docs before
running, and take the passwords from the `Octelium Postgres` / `Octelium
Redis` 1Password items (also on disk on remotebox under
`/var/lib/opnix/secrets/octelium/`):

```yaml
# bootstrap.yaml
kind: ClusterBootstrap
metadata: {}
spec:
  primaryStorage:
    postgresql:
      host: postgres.octelium.svc
      port: 5432
      username: octelium
      password: <...>
      database: octelium
  secondaryStorage:
    redis:
      host: redis.octelium.svc
      port: 6379
      password: <...>
```

```sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
octops init octelium.szpunar.cloud --bootstrap bootstrap.yaml
# then DNS (already in dns.nix) and TLS: octops cert --help
```

## Declarative Octelium resources

Octelium's own resources (Service, Policy, User, Group, …) live in Octelium's
API, not Kubernetes, so they're declared as nix attrsets in
`octelium-cluster.resources` (remotebox's `cluster.nix`) and applied by the
`octelium-resources-apply` oneshot on every boot/switch — edit nix, deploy,
converge. One-time setup after `octops init` + TLS:

```sh
# a scoped Policy instead of allow-all is better once you know what you need
octeliumctl create credential --user root --policy allow-all apply-token
```

Store the printed token in a 1Password item `Octelium Apply Token` (field
`password`) in the `Secrets` vault. The oneshot is inert while `resources`
is empty, skips cleanly while the token or cluster don't exist yet, and warns
(without failing the switch) if the API is unreachable; re-run manually with
`systemctl restart octelium-resources-apply`.

## Installing Cordium

```sh
octops install-package octelium.szpunar.cloud --package cordium
```

Cordium schedules sandboxes onto nodes labeled `octelium.com/node-mode-cordium=`
(magicbox, magicplank) and needs the dynamic `local-path` StorageClass (kept
enabled; data is node-local and non-replicated — Longhorn later if needed).

## Known risks / caveats

1. **TCP 443 conflict (blocking for ingress).** magicplank and remotebox run a
   dockerized Caddy that publishes host 443 (docker bypasses the NixOS
   firewall), while Octelium's ingress on dataplane nodes also wants 443. The
   NixOS module deliberately does not touch 443. Options: add a caddy layer4
   SNI-passthrough block for `octelium.szpunar.cloud` + `*.octelium...` to the
   Octelium ingress (same layer4 machinery as magicplank's TURNS 5349 —
   note caddy-l4 must then own the whole 443 listener), or expose the ingress
   on a NodePort and (magicplank) router-forward external 443 to it.
2. **etcd over WAN/tailnet**: remotebox↔home RTT via DERP relays can flap etcd
   heartbeats. Watch `etcd_server_leader_changes_seen_total`; raise
   heartbeat/election timeouts via `--etcd-arg` extraFlags if needed.
3. **Flannel over tailscale0**: MTU (~1230 for pods) is auto-derived from the
   interface; only pin manually if TCP stalls appear.
4. **No Cilium/Multus**: Octelium docs recommend Cilium/Calico + Multus for
   production multi-node; stock flannel matches Octelium's own quick-install.
   Accepted for now; revisit if service networking misbehaves.
5. **k3s + docker coexistence**: k3s uses embedded containerd, arion/docker is
   untouched. Keep `networking.firewall.checkReversePath = "loose"` (already
   set on all three hosts).
