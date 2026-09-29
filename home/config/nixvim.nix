{ config, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals.mapleader = " ";

    opts = {
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      termguicolors = true;
      updatetime = 250;
      timeoutlen = 400;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      smartindent = true;
      splitbelow = true;
      splitright = true;
      clipboard = "unnamedplus";
    };

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };

    plugins = {
      lualine.enable = true;
      web-devicons.enable = true;

      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
      };

      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
        # Chỉ cài parser cho ngôn ngữ đang dùng trong config và các tác vụ phổ biến.
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          c
          cpp
          json
          lua
          markdown
          markdown_inline
          nix
          python
          regex
          toml
          vim
          vimdoc
          yaml
        ];
      };

      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          lua_ls.enable = true;
          bashls.enable = true;
        };
        keymaps.lspBuf = {
          gd = "definition";
          gD = "references";
          K = "hover";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>write<CR>";
        options.desc = "Save file";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>quit<CR>";
        options.desc = "Quit";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Explore<CR>";
        options.desc = "File explorer";
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
        options.desc = "Clear search highlight";
      }
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
