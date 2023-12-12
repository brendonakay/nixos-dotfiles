{ config, pkgs, ... }:

{
    programs.tmux = {
      enable = true;
      #plugins = with pkgs; [
      #  tmuxPlugins.better-mouse-mode
      #];
      extraConfig = ''
set -g default-terminal "screen-256color"
set-window-option -g xterm-keys on
set-window-option -g mode-keys vi
set -g history-limit 30000

# solarized options
# from
# https://github.com/altercation/solarized/blob/master/tmux/tmuxcolors-256.conf
#### COLOUR (Solarized 256)

# default statusbar colors
set-option -g status-bg black #base02
set-option -g status-fg white #yellow
#set-option -g status-attr default

# default window title colors
#set-window-option -g window-status-fg colour244 #base0
#set-window-option -g window-status-bg default
#set-window-option -g window-status-attr dim

# active window title colors
#set-window-option -g window-status-current-fg colour166 #orange
#set-window-option -g window-status-current-bg default
#set-window-option -g window-status-current-attr bright

# pane border
#set-option -g pane-border-fg colour235 #base02
#set-option -g pane-active-border-fg colour240 #base01

# message text
#set-option -g message-bg colour235 #base02
#set-option -g message-fg colour166 #orange
#set -g message-fg white

# pane number display
set-option -g display-panes-active-colour colour33 #blue
#set-option -g display-panes-colour colour166 #orange

# center align window list
set -g status-justify left

# increase status-left length
set -g status-left-length 20

#
#set -g status-right '#[fg=colour233,bg=colour8,bold] %H:%M:%S'

# Mac clipboard
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"

# NVim stuff
set-option -sa terminal-overrides ',XXX:RGB'
set-option -sg escape-time 10

# List of plugins
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'samoshkin/tmux-plugin-sysstat'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'github_username/plugin_name#branch'
# set -g @plugin 'git@github.com:user/plugin'
# set -g @plugin 'git@bitbucket.com:user/plugin'

# tmux-plugin-sysstat
#set -g status-right "#{sysstat_cpu} | #{sysstat_mem} | #{sysstat_swap} | #{sysstat_loadavg} | #[fg=cyan]#(echo $USER)#[default]@#H"
set -g status-interval 2

# tmux-cpu
#set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
set -g status-right 'CPU:#{cpu_fg_color}#{cpu_percentage} #[fg=default]| #{sysstat_mem} | #{sysstat_swap} | #{sysstat_loadavg}'

# Set new panes to open in current directory
bind c new-window -c "#{pane_current_path}"
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
      '';
    };
}
