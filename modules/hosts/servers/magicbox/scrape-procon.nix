{inputs, ...}: {
  flake.modules.nixos.magicbox = {pkgs, ...}: {
    imports = [
      inputs.procon-scrape.nixosModules.default
    ];

    # License key from 1Password -> env file for the watcher.
    # Requires the 1Password item: op://Secrets/CloakBrowser Pro License/credential
    services.onepassword-secrets = {
      enable = true;
      secrets.proconLicense = {
        path = "/var/lib/opnix/secrets/scrape-procon/license";
        reference = "op://Secrets/CloakBrowser Pro License/credential";
        mode = "0640";
      };
    };

    systemd.services.scrape-procon-env = {
      after = ["opnix-secrets.service"];
      requires = ["opnix-secrets.service"];
      before = ["scrape-procon.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "scrape-procon-env" ''
          install -Dm 0640 /dev/null /var/lib/opnix/secrets/scrape-procon/env
          printf 'CLOAKBROWSER_LICENSE_KEY=%s\n' "$(cat /var/lib/opnix/secrets/scrape-procon/license)" \
            > /var/lib/opnix/secrets/scrape-procon/env
        '';
      };
    };

    # Windows .ttf files (segoeui*, tahoma*, verdana*, arial*) must be staged
    # at /var/lib/secrets/windows-fonts — Walmart's bot check needs them.
    # Without them Walmart stays a blind spot (no false positives, just no detection).
    services.scrape-procon = {
      enable = true;
      environmentFile = "/var/lib/opnix/secrets/scrape-procon/env";
      windowsFonts = "/var/lib/secrets/windows-fonts";

      settings = {
        ntfy = {
          server = "https://ntfy.sh";
          topic = "stock-zelda-19e54b";
          title_prefix = "IN STOCK";
        };
        interval = 30;
        jitter = 8;
        page_timeout = 45;
        user_agent = "";

        stores = {
          bestbuy_controller = {
            url = "https://www.bestbuy.com/product/nintendo-switch-2-pro-controller-the-legend-of-zelda-40th-anniversary-edition-multi/J7GSL57W27";
            settle_ms = 8000;
            checks = [
              {
                text_present = ["Add to Cart"];
                text_absent = ["Sold Out" "Coming Soon" "Check Stores"];
                css_present = ["[data-button-state='ADD_TO_CART'], button[data-sku-id='J7GSL57W27']"];
              }
            ];
          };

          gamestop_controller = {
            url = "https://www.gamestop.com/gaming-accessories/controllers/nintendo-switch-2/products/nintendo-switch-2-pro-controller-the-legend-of-zelda---40th-anniversary-edition/451609.html?20t75=";
            checks = [
              {
                text_present = ["Add to Cart"];
                text_absent = ["Sold Out" "Out of Stock" "Notify Me"];
                css_present = ["#add-to-cart, button[data-testid='add-to-cart']"];
              }
            ];
          };

          nintendo_controller = {
            url = "https://www.nintendo.com/us/store/products/nintendo-switch-2-pro-controller-the-legend-of-zelda-40th-anniversary-edition-127074/";
            checks = [
              {
                text_present = ["Add To Cart"];
                text_absent = ["Sold Out" "Sold out" "Out of stock" "Notify me"];
                css_present = ["button[data-testid='add-to-cart'], .add-to-cart button"];
              }
            ];
          };

          nintendo_stand = {
            url = "https://www.nintendo.com/us/store/products/nintendo-switch-2-pro-controller-display-stand-the-legend-of-zelda-40th-anniversary-edition-127076/";
            checks = [
              {
                text_present = ["Add To Cart"];
                text_absent = ["Sold Out" "Sold out" "Out of stock" "Notify me"];
                css_present = ["button[data-testid='add-to-cart'], .add-to-cart button"];
              }
            ];
          };

          target_console = {
            url = "https://www.target.com/p/nintendo-8482-switch-2-the-legend-of-zelda-40th-anniversary-edition-console-system/-/A-1013213521";
            checks = [
              {
                text_present = ["Add to cart"];
                text_absent = ["Sold out" "Out of stock" "See details" "Currently out of stock"];
                css_present = ["[data-test='orderCarryoverButton'], button[data-test='checkout']"];
              }
            ];
          };

          walmart_controller = {
            url = "https://www.walmart.com/ip/Nintendo-Switch-2-Pro-Controller-The-Legend-of-Zelda-40th-anniversary-Edition/20954470204";
            fingerprint = "windows";
            checks = [
              {
                text_present = ["Add to cart"];
                text_absent = ["Out of stock" "Get notified" "Add to list" "See similar"];
                css_present = ["button[data-tl-id='AddToCartMiniCart'], button[data-testid='add-to-cart']"];
              }
            ];
          };
        };
      };
    };
  };
}
