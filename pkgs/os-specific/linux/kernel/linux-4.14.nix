{ stdenv, buildPackages, fetchurl, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "4.14.111";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
    sha256 = "1s56819kkr7h48njk708f9gapy2hr97vxawp5qflv1izamb7s6gq";
  };
} // (args.argsOverride or {}))
