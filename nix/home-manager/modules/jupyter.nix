{ ... }:

let
  # Define common font settings
  fontFamily = "'FiraCode Nerd Font Mono', 'Fira Code', Monaco, 'Cascadia Code', Consolas, 'Courier New', monospace";
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
        };

    # Notification settings
    ".config/jupyter/lab/user-settings/@jupyterlab/apputils-extension/notification.jupyterlab-settings".text =
      builtins.toJSON {
        fetchNews = "false";
      };

    # Notebook settings
    ".config/jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings".text =
      builtins.toJSON {
        autoStartDefaultKernel = true;
        maxNumberOutputs = 50;
        recordTiming = true;
        scrollPastEnd = true;
        defaultCell = "code";
        kernelShutdown = false;
        sideBySideLeftMarginOverride = "10px";
        sideBySideRightMarginOverride = "10px";
        sideBySideOutputRatio = 1;
        windowingMode = "full";
        codeCellConfig = commonEditorSettings;
      };

    # File editor settings
    ".config/jupyter/lab/user-settings/@jupyterlab/fileeditor-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON {
        editorConfig = commonEditorSettings // {
          lineWrap = "on";
        };
      };

    # Console settings
    ".config/jupyter/lab/user-settings/@jupyterlab/console-extension/tracker.jupyterlab-settings".text =
      builtins.toJSON {
        promptCellConfig = {
          showHiddenCellsButton = true;
          defaultCollapsed = false;
          collapsedMetadata = {
            inputHidden = false;
            outputHidden = false;
          };
        };
      };

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
        sortNotebooksFirst = true;
        showFileCheckboxes = true;
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
          scrollback = 1000;
          screenReaderMode = false;
        };

    # Code completer settings
    ".config/jupyter/lab/user-settings/@jupyterlab/completer-extension/manager.jupyterlab-settings".text =
      builtins.toJSON {
        autoCompletion = true;
        showDocumentationPanel = true;
        providerTimeout = 1000;
      };

    # Status bar settings
    ".config/jupyter/lab/user-settings/@jupyterlab/statusbar-extension/plugin.jupyterlab-settings".text =
      builtins.toJSON {
        visible = true;
      };
  };
}
