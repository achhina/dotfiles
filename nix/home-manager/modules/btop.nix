{
  programs.btop = {
    enable = true;

    settings = {
      # Theme configuration
      color_theme = "Default";
      theme_background = true;
      truecolor = true;

      # Layout and display
      rounded_corners = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;

      # Process configuration
      proc_sorting = "memory";
      proc_reversed = false;
      proc_tree = true;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;

      # CPU configuration
      cpu_graph_upper = "Auto";
      cpu_graph_lower = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      temp_scale = "celsius";
      show_cpu_freq = true;

      # Memory configuration
      mem_graphs = true;
      mem_below_net = false;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;

      # Network configuration
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;

      # Battery configuration
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;

      # Miscellaneous
      clock_format = "%X";
      background_update = true;
      base_10_sizes = false;
      log_level = "WARNING";
    };
  };
}
