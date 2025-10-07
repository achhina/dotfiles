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
  # JupyterLab configuration managed via overrides
  # This allows users to modify settings in the UI while maintaining declarative defaults
  home.file.".config/jupyter/lab/settings/overrides.json".text =
    builtins.toJSON {
      "@jupyterlab/apputils-extension:themes" = {
        "adaptive-theme" = true;
        theme = "JupyterLab Dark High Contrast";
        "theme-scrollbars" = true;
      };

      "@jupyterlab/apputils-extension:notification" = {
        fetchNews = "false";
      };

      "@jupyterlab/notebook-extension:tracker" = {
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

      "@jupyterlab/fileeditor-extension:plugin" = {
        editorConfig = commonEditorSettings // {
          lineWrap = "on";
        };
      };

      "@jupyterlab/console-extension:tracker" = {
        promptCellConfig = {
          showHiddenCellsButton = true;
          defaultCollapsed = false;
          collapsedMetadata = {
            inputHidden = false;
            outputHidden = false;
          };
        };
      };

      "@jupyterlab/docmanager-extension:plugin" = {
        autosave = true;
        autosaveInterval = 5;
        lastModifiedCheckMargin = 500;
        renameUntitledFileOnSave = true;
        confirmClosingDocument = true;
      };

      "@jupyterlab/filebrowser-extension:browser" = {
        showLastModifiedColumn = true;
        showFileSizeColumn = true;
        showHiddenFiles = false;
        sortNotebooksFirst = true;
        showFileCheckboxes = true;
      };

      "@jupyterlab/terminal-extension:plugin" = {
        fontFamily = fontFamily;
        fontSize = fontSize;
        lineHeight = 1.3;
        theme = "dark";
        cursorBlink = true;
        scrollback = 1000;
        screenReaderMode = false;
      };

      "@jupyterlab/completer-extension:manager" = {
        autoCompletion = true;
        showDocumentationPanel = true;
        providerTimeout = 1000;
      };

      "@jupyterlab/statusbar-extension:plugin" = {
        visible = true;
      };

      "@jupyterlab/docregistry-extension:plugin" = {
        defaultViewers = {
          markdown = "Markdown Preview";
          csv = "CSV Viewer";
          tsv = "CSV Viewer";
          html = "HTML Preview";
          json = "JSON Viewer";
        };
      };
    };
}
