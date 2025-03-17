{ pkgs, ... }:
{
  programs.nixvim.extraPackages = with pkgs; [ shfmt ];
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    # lazyLoad.settings = {
    #   cmd = [
    #     "ConformInfo"
    #   ];
    #   event = [ "BufWrite" ];
    # };

    settings = {
      format_on_save = {
        lspFallback = true;
        timeoutMs = 500;
      };
      notify_on_error = true;

      formatters_by_ft = {
        liquidsoap = [ "liquidsoap-prettier" ];
        html = [
          "prettierd"
        ];
        css = [
          "prettierd"
        ];
        javascript = [
          "prettierd"
        ];
        javascriptreact = [
          "prettierd"
        ];
        typescript = [
          "prettierd"
        ];
        typescriptreact = [
          "prettierd"
        ];
        python = [ "black" ];
        lua = [ "stylua" ];
        nix = [ "nixfmt-rfc-style" ];
        markdown = [
          "prettierd"
        ];
        yaml = [
          "yamllint"
          "yamlfmt"
        ];
        terragrunt = [
          "hcl"
        ];
        bash = [
          "shfmt"
        ];
        sh = [
          "shfmt"
        ];
        haskell = [
          "hlint"
          "ormolu"
        ];
      };
    };
  };
}
