{ lib
, stdenv
, fetchFromGitHub
, cmake
, meson
, ninja
, boost
, pandoc
, pkg-config
, xercesc
, xalanc
, qt6Packages
, postgresql       # <-- pull in the PostgreSQL client (libpq) package
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "brewtarget";
  version = "4.1.0";

  src = fetchFromGitHub {
    owner = "Brewtarget";
    repo  = "brewtarget";
    rev   = "v${finalAttrs.version}";
    # sha256 for v4.1.0, computed via `nix-build` or `sha256sum`
    hash  = "sha256-0n2y58bsmkgdq8gy43s9vhwqnn5xamr15py73nx9zdp1mh81c9kd";
    fetchSubmodules = true;
  };

  # We want to switch the Meson database backend from the default ("sqlite")
  # to "postgresql".  Brewtarget’s meson.build exposes `database_backend` options.
  mesonFlags = [
    "-Ddatabase_backend=postgresql"
  ];

  postPatch = ''
    # Disable boost-stacktrace_backtrace (Debian‐only library)
    sed -i "/boostModules += 'stacktrace_backtrace'/ {N;N;d}" meson.build

    # Make libbacktrace not required, since we don’t run the trace script
    sed -i "/compiler\.find_library('backtrace'/ {n;s/true/false/}" meson.build

    # Disable static linking in meson.build
    sed -i 's/static : true/static : false/g' meson.build
  '';

  nativeBuildInputs = [
    meson
    cmake
    ninja
    pkg-config
    qt6Packages.wrapQtAppsHook
    pandoc
  ];

  buildInputs = [
    boost
    qt6Packages.qtbase
    qt6Packages.qttools
    qt6Packages.qtmultimedia
    qt6Packages.qtsvg
    xercesc
    xalanc

    # ← Here is the important bit: pull in libpq (PostgreSQL client/lib) so
    # Meson can find "-lpq" and associated headers.
    postgresql
  ];

  meta = {
    description = "Open source beer recipe creation tool with PostgreSQL support";
    mainProgram = "brewtarget";
    homepage = "http://www.brewtarget.org/";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [
      avnik
      mmahut
    ];
  };
})
