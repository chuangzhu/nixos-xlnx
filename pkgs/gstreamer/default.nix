{ callPackage, AudioToolbox, AVFoundation, Cocoa, CoreFoundation, CoreMedia, CoreServices, CoreVideo, DiskArbitration, Foundation, IOKit, MediaToolbox, OpenGL, VideoToolbox, libomxil-xlnx }:

{
  gstreamer = callPackage ./core { inherit CoreServices; };

  gstreamermm = callPackage ./gstreamermm { };

  gst-plugins-base = callPackage ./base { inherit Cocoa OpenGL; };

  gst-plugins-good = callPackage ./good { inherit Cocoa; };

  gst-plugins-bad = callPackage ./bad { inherit AudioToolbox AVFoundation CoreMedia CoreVideo Foundation MediaToolbox VideoToolbox; };

  gst-plugins-ugly = callPackage ./ugly { inherit CoreFoundation DiskArbitration IOKit; };

  gst-rtsp-server = callPackage ./rtsp-server { };

  gst-libav = callPackage ./libav { };

  gst-devtools = callPackage ./devtools { };

  gst-editing-services = callPackage ./ges { };

  gst-vaapi = callPackage ./vaapi { };

  gst-omx-zynqultrascaleplus = (callPackage ./omx { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: {
    mesonFlags = super.mesonFlags ++ [ "-Dheader_path=${libomxil-xlnx}/include/vcu-omx-il" ];
    postPatch = super.postPatch + ''
      substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${libomxil-xlnx}"
    '';
  });

  # note: gst-python is in ./python/default.nix - called under pythonPackages
}
