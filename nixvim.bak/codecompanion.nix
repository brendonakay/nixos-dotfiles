{
  programs.nixvim.plugins = {
    codecompanion = {
      enable = true;
      settings = {
        display = {
          diff = {
            provider = "mini_diff";
          };
        };
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
# An example with a different model used.
# {
#   buf = 10,
#   data = {
#     adapter = {
#       formatted_name = "Copilot",
#       model = "o3-mini-2025-01-31",
#       name = "copilot"
#     },
#     bufnr = 10,
#     id = 6107753,
#     strategy = "chat"
#   },
#   event = "User",
#   file = "CodeCompanionRequestStarted",
#   group = 14,
#   id = 30,
#   match = "CodeCompanionRequestStarted"
# }
