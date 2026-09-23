##########################################################################################
# Config Flags
##########################################################################################
# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=true

# Set to true if you need late_start service script
LATESTARTSERVICE=false

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this
# Construct your own list here
REPLACE="
"

# Set what we want to display when installing the module
print_modname() {
  ui_print "**************************************"
  ui_print "      Twemoji Resurrection v17.0.3 (58)"
  ui_print "     Maintained by Gontier Julien & deserthouse"
  ui_print "**************************************"
}

# Copy/extract the module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
  # Self-mount script for KernelSU/SukiSU/APatch without a mount metamodule
  unzip -o "$ZIPFILE" 'post-fs-data.sh' -d $MODPATH >&2
  chmod 0755 $MODPATH/post-fs-data.sh
  # WebUI (emoji verification gallery): managers render the "Open" button
  # only when webroot/index.html exists in the installed module dir
  unzip -o "$ZIPFILE" 'webroot/*' -d $MODPATH >&2
  [[ -d /sbin/.core/mirror ]] && MIRRORPATH=/sbin/.core/mirror || unset MIRRORPATH
  # Tolerant emoji-slot parser, same as post-fs-data.sh: family lang may list
  # several languages and font entries may carry any weight/style attributes —
  # collect every font slot so OEM vendor emoji fonts don't survive as
  # partial fallbacks. Android 15+ deprecates fonts.xml in favor of the
  # generated font_fallback.xml; try both and use whichever yields results.
  FONTFILES=$(sed -ne '/<family[^>]*lang="[^"]*und-Zsye[^"]*"[^>]*>/,/<\/family>/ {s/.*<font[^>]*>\([^<]*\)<\/font>.*/\1/p;}' $MIRRORPATH/system/etc/fonts.xml)
  [ -n "$FONTFILES" ] || FONTFILES=$(sed -ne '/<family[^>]*lang="[^"]*und-Zsye[^"]*"[^>]*>/,/<\/family>/ {s/.*<font[^>]*>\([^<]*\)<\/font>.*/\1/p;}' $MIRRORPATH/system/etc/font_fallback.xml)
  FONTFILES=$(echo "$FONTFILES" | tr ' ' '\n' | sort -u)
  for font in $FONTFILES
  do
    ln -s /system/fonts/NotoColorEmoji.ttf $MODPATH/system/fonts/$font
  done
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
}