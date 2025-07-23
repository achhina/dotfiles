{ ... }:

let
  # Define common font settings
  fontFamily = "Monaco, 'Cascadia Code', 'Fira Code', Consolas, 'Courier New', monospace";
  fontSize = 14;
  lineHeight = 1.4;
  tabSize = 4;
  wordWrapColumn = 80;

  # Common editor settings
  commonEditorSettings = {
    autoClosingBrackets = true;
    codeFolding = true;
    lineNumbers = true;
    matchBrackets = true;
    tabSize = tabSize;
    insertSpaces = true;
    wordWrapColumn = wordWrapColumn;
    showTrailingSpace = true;
    fontFamily = fontFamily;
    fontSize = fontSize;
    lineHeight = lineHeight;
    rulers = [ 80 ];
  };
in
{
  # JupyterLab configuration files managed by Home Manager
  home.file = {
    # Theme settings
    ".config/jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings".text =
      builtins.toJSON
        {
          "adaptive-theme" = true;
          theme = "JupyterLab Dark High Contrast";
          "theme-scrollbars" = true;
          increaseFontSize = false;
          overrideFontSize = null;
          overrideFontFamily = null;
          syntaxHighlightingTheme = "default";
        };

    # Notification settings
    ".config/jupyter/lab/user-settings/@jupyterlab/apputils-extension/notification.jupyterlab-settings".text =
      builtins.toJSON {
        fetchNews = "false";
      };

    # Notebook settings
    ".config/jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings".text =
      builtins.toJSON (
        commonEditorSettings
        // {
          autoStartDefaultKernel = true;
          maxNumberOutputs = 50;
          promptToDeleteCell = true;
          recordTiming = true;
          scrollPastEnd = true;
          defaultCell = "code";
          kernelShutdown = "unload";
          sideBySideLeftMarginOverride = "10px";
          sideBySideRightMarginOverride = "10px";
          sideBySideOutputRatio = 1;
          windowingMode = "full";
        }
      );

    # File editor settings
    ".config/jupyter/lab/user-settings/@jupyterlab/fileeditor-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON (
        commonEditorSettings
        // {
          lineWrap = "on";
        }
      );

    # Console settings
    ".config/jupyter/lab/user-settings/@jupyterlab/console-extension/tracker.jupyterlab-settings".text =
      builtins.toJSON
        (
          commonEditorSettings
          // {
            promptCellConfig = {
              showHiddenCellsButton = true;
              defaultCollapsed = false;
              collapsedMetadata = {
                inputHidden = false;
                outputHidden = false;
              };
            };
          }
        );

    # Document manager settings
    ".config/jupyter/lab/user-settings/@jupyterlab/docmanager-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON {
        autosave = true;
        autosaveInterval = 120;
        lastModifiedCheckMargin = 500;
        renameUntitledFileOnSave = true;
        confirmClosingDocument = true;
      };

    # File browser settings
    ".config/jupyter/lab/user-settings/@jupyterlab/filebrowser-extension/browser.jupyterlab-settings".text =
      builtins.toJSON {
        showLastModifiedColumn = true;
        showFileSizeColumn = true;
        showHiddenFiles = false;
        navigableView = true;
        sortBy = "name";
        sortNotebooksFirst = true;
        useCheckboxes = true;
        fileSizeColumnWidth = 100;
        lastModifiedColumnWidth = 140;
        nameColumnWidth = 300;
        refreshInterval = 30;
        confirmDelete = true;
        showFileExtensions = true;
      };

    # Terminal settings
    ".config/jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON
        {
          fontFamily = fontFamily;
          fontSize = fontSize;
          lineHeight = 1.3;
          theme = "dark";
          cursorBlink = true;
          cursorStyle = "block";
          scrollback = 1000;
          bellStyle = "none";
          copyOnSelect = false;
          pasteOnRightClick = true;
          screenReaderMode = false;
          fastScrollModifier = "alt";
          fastScrollSensitivity = 5;
          scrollSensitivity = 1;
          wordSeparator = " ()[]{}',\"";
          shellIntegration = true;
        };

    # Code completer settings
    ".config/jupyter/lab/user-settings/@jupyterlab/completer-extension/manager.jupyterlab-settings".text =
      builtins.toJSON {
        autoCompletion = true;
        includePerfectMatches = true;
        showDocumentationPanel = true;
        rankingFunction = "default";
        maxVisibleItems = 20;
        caseSensitive = false;
        completionThreshold = 1;
        providerTimeout = 1000;
        streaming = true;
        suppressContinuousHintingTimeout = 500;
        waitForBusyKernel = true;
      };

    # Status bar settings
    ".config/jupyter/lab/user-settings/@jupyterlab/statusbar-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON {
        showStatusBar = true;
        showLineColumn = true;
        showRunningKernel = true;
        showMemoryUsage = true;
        showTrustedStatus = true;
        showRunningSessions = true;
        position = "bottom";
        compactMode = false;
      };
  };
}
