c: traitlets.config.Config

# enable <C-x> + <C-e>
c.TerminalInteractiveShell.extra_open_editor_shortcuts = True

c.TerminalIPythonApp.display_banner = False

# Looks like you can configure ruff to be your formatter:
# https://github.com/ipython/ipython/issues/14532#issuecomment-2401691236
c.TerminalInteractiveShell.autoformatter = "black"
