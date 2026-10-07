{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.zynq;
in

{
  options.hardware.zynq.watchdog = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable the Zynq UltraScale+ MPSoC FPD system watchdog (SWDT0).

        This enables the `watchdog0` device-tree node, has systemd pet it, and
        builds PMUFW with the error management module so that a watchdog timeout
        triggers a system reset. Without that module, FSBL disarms the SWDT reset
        path before handoff and nothing re-arms it.

        If you set {option}`hardware.zynq.pmufw` yourself, build it with the flags
        this adds to {option}`hardware.zynq.pmufwExtraCFlags`.
      '';
    };
  };

  config = lib.mkIf cfg.watchdog.enable {
    assertions = [
      {
        assertion = cfg.platform == "zynqmp";
        message = "hardware.zynq.watchdog is only supported on Zynq UltraScale+ MPSoC (platform = \"zynqmp\").";
      }
    ];

    hardware.zynq.pmufwExtraCFlags = [
      # Re-arms the FPD/LPD SWDT system reset after FSBL hands off
      "-DENABLE_EM"
      # Free PMU RAM, otherwise ENABLE_EM overflows it
      "-DENABLE_FPGA_READ_CONFIG_DATA_VAL=0U"
      "-DENABLE_FPGA_READ_CONFIG_REG_VAL=0U"
      "-DXPFW_PRINT_VAL=0U"
    ];

    # zynqmp.dtsi already sets reset-on-timeout; restated in case it ever changes
    hardware.deviceTree.overlays = [
      {
        name = "zynqmp-watchdog";
        dtsText = ''
          /dts-v1/;
          /plugin/;
          / { compatible = "xlnx,zynqmp"; };
          &watchdog0 {
            status = "okay";
            reset-on-timeout;
          };
        '';
      }
    ];

    # The Cadence WDT caps out at 516 s, so keep these below that
    systemd.settings.Manager = {
      RuntimeWatchdogSec = lib.mkDefault "30s";
      RebootWatchdogSec = lib.mkDefault "5min";
    };
  };
}
