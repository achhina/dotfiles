{
  # IPython default profile configuration
  home.file.".config/ipython/profile_default/ipython_config.py".text = ''
    c: traitlets.config.Config

    # =============================================================================
    # IPython Configuration
    # =============================================================================

    # =============================================================================
    # Core Interface Settings
    # =============================================================================

    # Disable startup banner for cleaner interface
    c.TerminalIPythonApp.display_banner = False

    # Enable extra editor shortcuts (Ctrl-x + Ctrl-e to open external editor)
    c.TerminalInteractiveShell.extra_open_editor_shortcuts = True

    # Disable exit confirmation for faster workflow
    c.TerminalInteractiveShell.confirm_exit = False

    # Enable automagic - use magic commands without % prefix
    c.InteractiveShell.automagic = True

    # Enable automatic indentation for code blocks
    # c.InteractiveShell.autoindent = True

    # =============================================================================
    # Code Formatting
    # =============================================================================

    # Use black for automatic code formatting in the REPL
    # Note: Ruff workaround available at https://github.com/ipython/ipython/issues/14532#issuecomment-2401691236
    c.TerminalInteractiveShell.autoformatter = "black"

    # =============================================================================
    # Tab Completion Settings
    # =============================================================================

    # Enable greedy completion for more aggressive tab completion
    c.IPCompleter.greedy = True

    # Use Jedi for advanced completion (disable if causing issues)
    c.IPCompleter.use_jedi = True

    # Merge completion results from different sources
    c.IPCompleter.merge_completions = True

    # =============================================================================
    # History Configuration
    # =============================================================================

    # Increase history length for better recall
    c.HistoryManager.connection_options = {"timeout": 20}

    # Remove duplicate history entries
    c.HistoryManager.db_log_output = False

    # =============================================================================
    # Display and Output Settings
    # =============================================================================

    # Use context mode for better error tracebacks
    c.InteractiveShell.xmode = "Context"

    # Set color scheme (try 'NoColor', 'LightBG', or 'Linux')
    c.InteractiveShell.colors = "LightBG"

    # Cache output results for easy recall with _1, _2, etc.
    c.InteractiveShell.cache_size = 1000

    # =============================================================================
    # Performance Optimization
    # =============================================================================

    # Limit AST node interactivity for better performance
    c.InteractiveShell.ast_node_interactivity = "last_expr"

    # =============================================================================
    # Auto-imports for Common Libraries
    # =============================================================================

    # Automatically import commonly available libraries at startup
    c.InteractiveShellApp.exec_lines = [
        "import json",
        "import os",
        "import sys",
        "from pathlib import Path",
        "from datetime import datetime, timedelta",
        "# Auto-imported: json, os, sys, Path, datetime",
        "# Note: Add numpy, pandas, matplotlib, seaborn, requests if installed",
    ]

    # =============================================================================
    # Custom Aliases
    # =============================================================================

    # Create useful command aliases
    c.AliasManager.user_aliases = [
        ("la", "ls -la"),  # Detailed file listing
        ("ll", "ls -l"),  # Long file listing
        ("cls", "clear"),  # Clear screen
        ("h", "history"),  # Show command history
        ("reload", "%reload_ext"),  # Quick extension reload
    ]

    # =============================================================================
    # Editor Configuration
    # =============================================================================

    # Set preferred editor (will use system default if not set)
    # c.TerminalInteractiveShell.editor = 'nvim'

    # Better paste handling is built into modern IPython

    # =============================================================================
    # Advanced Features & Memory Management
    # =============================================================================

    # Enhanced result caching - stores outputs for easy recall
    c.InteractiveShell.cache_size = 1000

    # Enable deep reload extension for better module development workflow
    # (use %load_ext autoreload and %autoreload 2 for auto-reloading)

    # =============================================================================
    # Magic Command Shortcuts
    # =============================================================================

    # Auto-execute helpful magic commands at startup (commented out by default)
    # Uncomment any you find useful:
    c.InteractiveShellApp.exec_lines += [
        "%load_ext autoreload",  # Auto-reload modules when they change
        "%autoreload 2",  # Reload all modules except excluded ones
        # "%matplotlib inline",  # Enable inline plotting
        # '%config InlineBackend.figure_format = "retina"',  # High-res plots
    ]

    # =============================================================================
    # Session Logging (Optional)
    # =============================================================================

    # Uncomment to enable session logging for debugging
    # c.TerminalIPythonApp.log_level = 30  # WARNING level
    # c.InteractiveShell.logstart = True
    # c.InteractiveShell.logfile = '~/.ipython/ipython_log.py'

    # =============================================================================
    # Keyboard Shortcuts & Navigation
    # =============================================================================

    # Better history search (already enabled by default in modern IPython)
    # Use Ctrl+R for reverse history search
    # Use Up/Down arrows for prefix history search

    # =============================================================================
    # Development Workflow Enhancements
    # =============================================================================

    # Better debugging support
    c.InteractiveShell.separate_in = "\n"
    c.InteractiveShell.separate_out = ""
    c.InteractiveShell.separate_out2 = ""

    # Enhanced object introspection
    c.InteractiveShell.object_info_string_level = 2
  '';

  # IPython research profile configuration
  # Launch with: ipython --profile=research
  home.file.".config/ipython/profile_research/ipython_config.py".text = ''
    c: traitlets.config.Config

    # =============================================================================
    # IPython Research Profile Configuration
    # =============================================================================

    # Core interface settings
    c.TerminalIPythonApp.display_banner = False
    c.TerminalInteractiveShell.extra_open_editor_shortcuts = True
    c.TerminalInteractiveShell.confirm_exit = False
    c.InteractiveShell.automagic = True
    c.InteractiveShell.xmode = "Context"
    c.InteractiveShell.colors = "LightBG"
    c.InteractiveShell.cache_size = 1000
    c.IPCompleter.greedy = True
    c.IPCompleter.use_jedi = True
    c.IPCompleter.merge_completions = True

    # Research-specific settings
    c.InteractiveShell.ast_node_interactivity = "last_expr_or_assign"  # Show assignments

    # History configuration
    c.HistoryManager.connection_options = {"timeout": 20}
    c.HistoryManager.db_log_output = False

    # Code formatting
    c.TerminalInteractiveShell.autoformatter = "black"

    # Magic commands for research workflow
    c.InteractiveShellApp.exec_lines = [
        "%load_ext autoreload",
        "%autoreload 2",
    ]

    # Custom aliases
    c.AliasManager.user_aliases = [
        ("la", "ls -la"),
        ("ll", "ls -l"),
        ("cls", "clear"),
        ("h", "history"),
    ]

    # Development workflow enhancements
    c.InteractiveShell.separate_in = "\n"
    c.InteractiveShell.separate_out = ""
    c.InteractiveShell.separate_out2 = ""

    # Enhanced object introspection
    c.InteractiveShell.object_info_string_level = 2
  '';

  # Research profile startup files
  home.file.".config/ipython/profile_research/startup/00-imports.py".text = ''
    """Auto-import research libraries"""
    import importlib
    from collections import namedtuple

    Import = namedtuple('Import', ['module', 'alias', 'post_import'])

    IMPORTS = [
        # Core
        Import('sys', None, None),
        Import('os', None, None),
        Import('pathlib', 'Path', None),
        # Scientific computing
        Import('numpy', 'np', None),
        Import('pandas', 'pd', None),
        Import('matplotlib.pyplot', 'plt', None),
        Import('seaborn', 'sns', lambda: __import__('seaborn').set_theme()),
        # ML frameworks
        Import('sklearn', None, None),
        Import('torch', None, None),
        Import('tensorflow', 'tf', None),
        # Utilities
        Import('scipy', None, None),
        Import('tqdm', 'tqdm', None),
        Import('IPython.display', ['display', 'HTML', 'Markdown'], None),
    ]

    for imp in IMPORTS:
        try:
            mod = importlib.import_module(imp.module)

            # Handle different import patterns
            if isinstance(imp.alias, list):
                # from X import a, b, c
                for attr in imp.alias:
                    globals()[attr] = getattr(mod, attr)
            elif imp.alias:
                # import X as Y
                globals()[imp.alias] = mod
            else:
                # import X
                globals()[imp.module.split('.')[0]] = mod

            if imp.post_import:
                imp.post_import()

            print(f'✓ {imp.module}')
        except ImportError:
            print(f'✗ {imp.module}')

    print('\nResearch environment ready!')
  '';
}
