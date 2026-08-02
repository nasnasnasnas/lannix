{config, ...}: {
  # Unsloth LLM fine-tuning workbench.
  #
  # The upstream `docker run` publishes 8888 (Jupyter), 8000 (workspace app) and
  # 2222->22 (ssh). Only 8000 is fronted by Caddy here; 22 and 8888 are ignored.
  #
  # The official unsloth/unsloth image is CUDA-only (no ROCm build), so on the
  # AMD-APU host it runs CPU-only — no `--gpus`/device passthrough is wired.
  flake.services.unsloth = {
    domains ? [],
    networks ? [],
    container_name ? "unsloth",
    image ? config.flake.lib.image "unsloth/unsloth",
    restart ? "unless-stopped",
    port ? 8000,
    dataDir ? "/home/magicbox/data/unsloth",
    environment ? {},
    volumes ? [],
  }: {
    inherit domains container_name image restart networks environment;
    caddy_port = port;
    healthcheck = {
      test = ["CMD" "python3" "-c" "import urllib.request as u,sys;sys.exit(0 if u.urlopen('http://127.0.0.1:8000/api/status',timeout=5).status==200 else 1)"];
      interval = "30s";
      timeout = "10s";
      retries = 5;
      start_period = "300s";
    };
    volumes = volumes ++ ["${dataDir}/work:/workspace/work"];
  };
}
