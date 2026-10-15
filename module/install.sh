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
  ui_print "      Twemoji Resurrection v17.0.3 (59)"
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
  # Shared slot discovery used by this installer, the boot self-mount and
  # the WebUI live check — one parser, no drift between the three
  unzip -o "$ZIPFILE" 'bin/*' -d $MODPATH >&2
  # WebUI (emoji verification gallery): managers render the "Open" button
  # only when webroot/index.html exists in the installed module dir
  unzip -o "$ZIPFILE" 'webroot/*' -d $MODPATH >&2
  [[ -d /sbin/.core/mirror ]] && MIRRORPATH=/sbin/.core/mirror || unset MIRRORPATH
  # Discover every emoji slot across fonts.xml / font_fallback.xml / product
  # customization (see bin/emoji-slots.sh) and symlink each one to the module
  # font so Magic Mount can overlay it. Recovery installs read the configs
  # through the Magisk mirror; symlink targets keep real device paths.
  if [ -n "$MIRRORPATH" ]; then
    SLOTS=$(EMOJI_SLOTS_READ_ROOT=$MIRRORPATH sh $MODPATH/bin/emoji-slots.sh list)
  else
    SLOTS=$(sh $MODPATH/bin/emoji-slots.sh list)
  fi
  for p in $SLOTS
  do
    mkdir -p "$MODPATH$(dirname "$p")"
    ln -s /system/fonts/NotoColorEmoji.ttf "$MODPATH$p"
  done
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
}