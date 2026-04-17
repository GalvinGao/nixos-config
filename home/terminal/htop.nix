{ ... }:

{
  programs.htop = {
    enable = true;
    settings = {
      hide_kernel_threads = true;
      highlight_base_name = false;
      highlight_deleted_exe = true;
      highlight_megabytes = true;
      highlight_threads = true;
      show_program_path = true;
      find_comm_in_cmdline = true;
      strip_exe_from_cmdline = true;
      header_margin = true;
      screen_tabs = true;
      delay = 15;
      header_layout = "two_50_50";
      column_meters_0 = "LeftCPUs2 Memory Swap";
      column_meter_modes_0 = "1 1 1";
      column_meters_1 = "RightCPUs2 Tasks LoadAverage Uptime";
      column_meter_modes_1 = "1 2 2 2";
      tree_view = false;
      sort_key = 46;
      sort_direction = -1;
    };
  };
}
