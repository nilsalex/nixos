{
  autoPatchelfHook,
  fetchurl,
  libcap_ng,
  lib,
  stdenv,
  versionCheckHook,
}:

let
  sources = {
    "x86_64-linux" = {
      url = "https://github.com/superradcompany/microsandbox/releases/download/v0.7.7/microsandbox-linux-x86_64.tar.gz";
      hash = "sha256-s8xKXj9S392Tim9nrEqalZ3f4wS6tW3klkBEuGE/Abs=";
    };
    "aarch64-linux" = {
      url = "https://github.com/superradcompany/microsandbox/releases/download/v0.7.7/microsandbox-linux-aarch64.tar.gz";
      hash = "sha256-iZex6nbeWGifttD6ezKvb76MvCRhLaQLFopbQzx9gxg=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "microsandbox: unsupported platform ${stdenv.hostPlatform.system}");

  libkrunfwVersion = "5.6.1";
  libkrunfwAbi = "5";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "microsandbox";
  version = "0.7.7";

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    libcap_ng
    stdenv.cc.cc.lib
  ];

  appendRunpaths = [ "${placeholder "out"}/lib" ];

  installPhase = ''
    runHook preInstall

    install -Dm755 msb -t $out/bin
    install -Dm644 libkrunfw.so.${libkrunfwVersion} -t $out/lib
    ln -s libkrunfw.so.${libkrunfwVersion} $out/lib/libkrunfw.so.${libkrunfwAbi}
    ln -s libkrunfw.so.${libkrunfwAbi} $out/lib/libkrunfw.so

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/msb";
  versionCheckProgramArg = "--version";

  meta = {
    description = "msb CLI for microsandbox: easy, fast, local microVMs";
    homepage = "https://github.com/superradcompany/microsandbox";
    license = lib.licenses.asl20;
    mainProgram = "msb";
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
