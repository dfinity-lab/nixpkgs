{ stdenv, fetchurl, autoPatchelfHook, atomEnv, makeWrapper, makeDesktopItem, gtk3, wrapGAppsHook }:

let
  description = "Trilium Notes is a hierarchical note taking application with focus on building large personal knowledge bases.";
  desktopItem = makeDesktopItem {
    name = "Trilium";
    exec = "trilium";
    icon = "trilium";
    comment = description;
    desktopName = "Trilium Notes";
    categories = "Office";
  };

in stdenv.mkDerivation rec {
  name = "trilium-${version}";
  version = "0.29.1";

  src = fetchurl {
    url = "https://github.com/zadam/trilium/releases/download/v${version}/trilium-linux-x64-${version}.tar.xz";
    sha256 = "1yyd650l628x3kvyn73d5b35sj7ixmdlqkb6h1swdjp0z2n00w4w";
  };

  # Fetch from source repo, no longer included in release.
  # (they did special-case icon.png but we want the scalable svg)
  # Use the version here to ensure we get any changes.
  trilium_svg = fetchurl {
    url = "https://raw.githubusercontent.com/zadam/trilium/v${version}/src/public/images/trilium.svg";
    sha256 = "1rgj7pza20yndfp8n12k93jyprym02hqah36fkk2b3if3kcmwnfg";
  };


  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook
  ];

  buildInputs = [ atomEnv.packages gtk3 ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/trilium
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}

    cp -r ./* $out/share/trilium
    ln -s $out/share/trilium/trilium $out/bin/trilium

    ln -s ${trilium_svg} $out/share/icons/hicolor/scalable/apps/trilium.svg
    cp ${desktopItem}/share/applications/* $out/share/applications
  '';

  # LD_LIBRARY_PATH "shouldn't" be needed, remove when possible :)
  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${atomEnv.libPath})
  '';

  dontStrip = true;

  meta = with stdenv.lib; {
    inherit description;
    homepage = https://github.com/zadam/trilium;
    license = licenses.agpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ emmanuelrosa dtzWill ];
  };
}
