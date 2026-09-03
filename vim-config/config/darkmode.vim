vim9script
# auto-dark-mode.nvim followed the macOS appearance setting. Vim has no hook for
# the system theme, so poll `defaults read` on a timer. Sourced after
# packloadall because it needs everforest on 'runtimepath'.

def MacosBackground(): string
  if !has('mac') || !executable('defaults')
    return 'dark'
  endif
  # AppleInterfaceStyle only exists while dark mode is on.
  return system('defaults read -g AppleInterfaceStyle 2>/dev/null') =~? 'dark' ? 'dark' : 'light'
enddef

def ApplyBackground(id: number = 0)
  var background = MacosBackground()
  if &background ==# background && get(g:, 'colors_name', '') ==# 'everforest'
    return
  endif

  &background = background
  silent! colorscheme everforest

  # Re-reading the colorscheme drops lightline's palette.
  if exists('*lightline#colorscheme')
    lightline#colorscheme()
  endif
enddef

ApplyBackground()

# Frequent enough to catch the automatic switch at sunset without the poll
# showing up in a profile.
timer_start(30000, ApplyBackground, {repeat: -1})
