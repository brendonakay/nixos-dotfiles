{
  programs.nixvim.plugins = {
    codecompanion = {
      enable = true;
      settings = {
        adapters = {
          copilot = "copilot";
        };
        opts = {
          log_level = "TRACE";
          send_code = true;
          use_default_actions = true;
          use_default_prompts = true;
        };
        strategies = {
          agent = {
            adapter = "copilot";
          };
          chat = {
            adapter = "copilot";
          };
          inline = {
            adapter = "copilot";
          };
        };

      };
    };
  };
}
