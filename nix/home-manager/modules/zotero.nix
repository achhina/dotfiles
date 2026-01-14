{ config, lib, pkgs, ... }:

let
  # Determine platform-specific paths
  zoteroConfigBase = if pkgs.stdenv.isDarwin
    then "Library/Application Support/Zotero"
    else ".zotero";

  # Zotero data directory location
  zoteroDataDir = "${config.home.homeDirectory}/Zotero";
in
{
  # Configure profiles.ini with fixed profile name
  home.file."${zoteroConfigBase}/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=1
    Path=Profiles/default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  # Declarative Zotero preferences via user.js
  home.file."${zoteroConfigBase}/Profiles/default/user.js" = {
    text = ''
      // ============================================================================
      // Zotero Preferences (managed by Home Manager)
      // ============================================================================

      // PDF Reader Settings
      // Keep PDFs in light mode while using dark UI
      user_pref("extensions.zotero.reader.contentDarkMode", false);

      // Automatic File Handling
      // Auto-download PDFs when saving items from web
      user_pref("extensions.zotero.automaticAttachments", true);
      user_pref("extensions.zotero.downloadAssociatedFiles", true);

      // Automatically take snapshots when creating items from web pages
      user_pref("extensions.zotero.automaticSnapshots", true);

      // Sync Configuration
      user_pref("extensions.zotero.sync.autoSync", true);
      user_pref("extensions.zotero.sync.server.username", "achhina");

      // Data Directory
      user_pref("extensions.zotero.dataDir", "${zoteroDataDir}");

      // Skip Firefox profile access check (not using Firefox)
      user_pref("extensions.zotero.firstRun.skipFirefoxProfileAccessCheck", true);

      // Update Settings
      // Disable auto-updates (managed by Nix)
      user_pref("app.update.auto", false);
      user_pref("app.update.enabled", false);

      // HTTP Server for local API access
      user_pref("extensions.zotero.httpServer.localAPI.enabled", true);

      // Interface Preferences
      // Keep all panes open by default
      user_pref("extensions.zotero.panes.abstract.open", true);
      user_pref("extensions.zotero.panes.attachments.open", true);
      user_pref("extensions.zotero.panes.notes.open", true);
      user_pref("extensions.zotero.panes.tags.open", true);
    '';

    # Run backup before Home Manager overwrites the file
    onChange = ''
      USER_JS="${config.home.homeDirectory}/${zoteroConfigBase}/Profiles/default/user.js"
      if [ -f "$USER_JS" ] && [ ! -L "$USER_JS" ]; then
        BACKUP="$USER_JS.backup-$(date +%Y%m%d-%H%M%S)"
        echo "Backing up existing user.js to $BACKUP"
        cp "$USER_JS" "$BACKUP"
      fi
    '';
  };

  # Ensure Zotero data directory exists
  home.activation.createZoteroDataDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${zoteroDataDir}"
    echo "Zotero data directory: ${zoteroDataDir}"
  '';
}
