{...}: {
  flake.dnsRecords."szpunar.cloud" = let
    aRecordIP = "10.177.177.117";
    mkA = name: {
      inherit name;
      type = "A";
      content = aRecordIP;
    };
    mkCNAME = name: target: {
      inherit name;
      type = "CNAME";
      content = target;
    };
  in
    (map mkA [
      "request"
      "test"
    ])
    ++ [
      (mkCNAME "budget" "kickass-flounder.pikapod.net")
      (mkCNAME "kickass-geese" "kickass-flounder.pikapod.net")
    ];

  flake.dnsRecords."nea.rip" = let
    aRecordIP = "10.177.177.117";
    mkA = name: {
      inherit name;
      type = "A";
      content = aRecordIP;
    };
  in (map mkA [
    "request"
    "test"
  ]);
}
