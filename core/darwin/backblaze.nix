{ ... }:

let
  exclusionRules = ./bzexcluderules_editable.xml;
  targetDir = "/Library/Backblaze.bzpkg/bzdata";
  targetFile = "${targetDir}/bzexcluderules_editable.xml";
in
{
  system.activationScripts.postActivation.text = ''
    # Deploy Backblaze exclusion rules if Backblaze is installed
    if [ -d "${targetDir}" ]; then
      cp ${exclusionRules} ${targetFile}
      chmod 644 ${targetFile}
      echo "Backblaze exclusion rules deployed to ${targetFile}"
    else
      echo "Backblaze not installed (${targetDir} missing), skipping exclusion rules"
    fi
  '';
}
