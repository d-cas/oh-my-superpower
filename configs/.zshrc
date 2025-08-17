typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
# ============================================================================
# POWERLEVEL10K INSTANT PROMPT (keep at top)
# ============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ============================================================================
# SAFETY FUNCTIONS
# ============================================================================

# Protect against accidental `rm -rf`
rm() {
  if [[ "$*" == *"-rf"* ]]; then
    echo "⚠️  You're using 'rm -rf'. Proceed with caution."
    read -r -p "Are you sure? (y/n): " confirm
    [[ $confirm == [yY] ]] || return 1
  fi
  command rm -i "$@"
}

# Fix terminal compatibility issues
if [[ "$TERM" == "xterm-kitty" ]]; then
    export TERM="xterm-256color"
fi

# Protect sudo from bypassing alias/functions
alias sudo='sudo '

# Safe delete for Linux (using trash-cli if available)
if command -v trash-put >/dev/null 2>&1; then
    alias rr='trash-put'
    alias trashed='trash-put'
elif command -v gio >/dev/null 2>&1; then
    alias rr='gio trash'
    alias trashed='gio trash'
else
    alias rr='rm -i'
    alias trashed='rm -i'
fi

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# 1Password SSH Agent
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Editor and browser preferences
export EDITOR=nano
export BROWSER=firefox

# Pager settings
export PAGER=less
export LESS=-R

# Add your custom bin directory to PATH
export PATH="$HOME/bin:$PATH"

# ============================================================================
# ZSH PLUGINS (Endeavour OS paths)
# ============================================================================

# Check if plugins are installed and source them
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ============================================================================
# OH MY ZSH + POWERLEVEL10K
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    colored-man-pages
    command-not-found
    sudo
    extract
    web-search
    copypath
    copybuffer
    dirhistory
)

# Load Oh My Zsh
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Load Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ============================================================================
# ALIASES (RESTORED FROM YOUR CONFIG)
# ============================================================================

# Directory navigation
alias ...=../..
alias ....=../../..
alias .....=../../../..
alias ......=../../../../..

# Directory shortcuts with numbers
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# Better ls
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias lsa='ls -lah'
alias ls='ls --color=tty'

# Directory operations
alias md='mkdir -p'
alias rd=rmdir

# Config editing
alias zshconfig='subl ~/.zshrc'

# Rclone with your TrueNAS config (adapted for Linux mount)
alias rclone='rclone --config="/mnt/truenas/rclone/rclone.conf"'

# Grep with better defaults
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'

# ============================================================================
# PRIVACY MODE & SELECTIVE LOGGING
# ============================================================================

# Logging directory setup
LOGDIR="$HOME/terminal_logs"
mkdir -p "$LOGDIR"

# Privacy mode toggle - stops all logging and nukes screen/scrollback
look_away_bro() {
    # Save current state
    export PRIVACY_MODE=1
    export LOGGING_PAUSED=1  # Pause file logging
    
    # Disable command history temporarily
    set +o hist_verify
    unset HISTFILE
    
    # Clear everything visible
    printf "\033[2J\033[3J\033[1;1H"
    
    echo "🙈 PRIVACY MODE ACTIVATED"
    echo "📵 File logging paused"
    echo "Type sensitive commands freely..."
    echo "Run 'ok_look' when done"
}

ok_look() {
    if [[ $PRIVACY_MODE != 1 ]]; then
        echo "Privacy mode wasn't active, bro"
        return
    fi
    
    # Nuclear option - clear everything
    printf "\033[2J\033[3J\033[1;1H"
    
    # Re-enable history
    export HISTFILE=~/.zsh_history
    set -o hist_verify
    
    # Clean up
    unset PRIVACY_MODE
    unset LOGGING_PAUSED  # Resume logging
    
    echo "👀 ALL CLEAR - Welcome back!"
    echo "Everything nuked from orbit"
    if [[ -n "$CURRENT_LOG" ]]; then
        echo "📝 File logging resumed"
    fi
}

# Start logging current session
start_log() {
    if [[ -n "$CURRENT_LOG" ]]; then
        echo "Already logging to: $(basename "$CURRENT_LOG")"
        return
    fi
    
    local session_name="${1:-session}"
    CURRENT_LOG="$LOGDIR/${session_name}_$(date +%Y%m%d_%H%M%S).log"
    
    echo "🎬 Started logging to: $(basename "$CURRENT_LOG")"
    echo "# Session started: $(date)" >> "$CURRENT_LOG"
    echo "# Working directory: $(pwd)" >> "$CURRENT_LOG"
    echo "# ============================================" >> "$CURRENT_LOG"
    
    # Start capturing all output
    exec > >(tee -a "$CURRENT_LOG")
    exec 2>&1
}

# Stop logging
stop_log() {
    if [[ -z "$CURRENT_LOG" ]]; then
        echo "Not currently logging"
        return
    fi
    
    echo "# ============================================" >> "$CURRENT_LOG"
    echo "# Session ended: $(date)" >> "$CURRENT_LOG"
    echo "🛑 Stopped logging: $(basename "$CURRENT_LOG")"
    
    # Reset output to terminal only
    exec > /dev/tty
    exec 2>&1
    
    unset CURRENT_LOG
}

# Show current log status
log_status() {
    if [[ -n "$CURRENT_LOG" ]]; then
        echo "📝 Currently logging to: $(basename "$CURRENT_LOG")"
        echo "   Full path: $CURRENT_LOG"
        echo "   Lines: $(wc -l < "$CURRENT_LOG" 2>/dev/null || echo "0")"
        echo "   Size: $(du -h "$CURRENT_LOG" 2>/dev/null | cut -f1 || echo "0B")"
        if [[ "$LOGGING_PAUSED" == "1" ]]; then
            echo "   Status: ⏸️  PAUSED (privacy mode)"
        else
            echo "   Status: ▶️  ACTIVE"
        fi
    else
        echo "📵 Not logging"
    fi
}

# List recent logs
logs() {
    echo "Recent terminal logs:"
    if [[ -d "$LOGDIR" ]] && [[ -n "$(ls -A "$LOGDIR" 2>/dev/null)" ]]; then
        ls -lath "$LOGDIR"/*.log 2>/dev/null | head -10
    else
        echo "No logs found in $LOGDIR"
    fi
}

# View a log file
viewlog() {
    local logfile="$1"
    if [[ -z "$logfile" ]]; then
        echo "Available logs:"
        if [[ -d "$LOGDIR" ]]; then
            ls "$LOGDIR"/*.log 2>/dev/null | xargs -I{} basename {} .log | nl -w2 -s'. '
            echo -n "Pick a log number (or press Enter to cancel): "
            read num
            if [[ -n "$num" && "$num" =~ ^[0-9]+$ ]]; then
                logfile=$(ls "$LOGDIR"/*.log 2>/dev/null | sed -n "${num}p")
            else
                echo "Cancelled"
                return
            fi
        else
            echo "No logs directory found"
            return
        fi
    elif [[ "$logfile" != /* ]]; then
        logfile="$LOGDIR/$logfile"
        [[ "$logfile" != *.log ]] && logfile="${logfile}.log"
    fi
    
    if [[ -f "$logfile" ]]; then
        echo "📖 Viewing: $(basename "$logfile")"
        less "$logfile"
    else
        echo "❌ Log not found: $logfile"
    fi
}

# Search through logs
search_logs() {
    local search_term="$1"
    if [[ -z "$search_term" ]]; then
        echo "Usage: search_logs <search_term>"
        return 1
    fi
    
    echo "🔍 Searching logs for: '$search_term'"
    if [[ -d "$LOGDIR" ]]; then
        grep -r --color=always -n "$search_term" "$LOGDIR"/*.log 2>/dev/null
    else
        echo "No logs directory found"
    fi
}

# ============================================================================
# UTILITY ALIASES AND FUNCTIONS
# ============================================================================

# Clear screen AND scrollback 
alias cls='printf "\033[2J\033[3J\033[1;1H"'

# Just nuke scrollback
alias nuke='printf "\033[3J"'

# Quick access to privacy mode
alias privacy='look_away_bro'

# Quick log management
alias logstart='start_log'
alias logstop='stop_log'
alias logstat='log_status'

# ULTIMATE BIG DICK ENERGY HELP FUNCTION
show_help() {
    # Massive ASCII title
    figlet "SUPERPOWERS" | lolcat -f -F 0.3 -p 300 -t
    echo ""
    
    # Top separator
    echo "═══════════════════════════════════════════════════════════════" | lolcat -f -F 0.1 -p 200
    
    # Privacy section
    printf "   \033[1;33mPrivacy:\033[0m "
    echo "look_away_bro / ok_look" | lolcat -f -F 0.2 -p 120 -t
    echo "───────────────────────────────────────────────────────────────" | lolcat -f -F 0.1 -p 50
    
    # Logging section  
    printf "   \033[1;33mLogging:\033[0m "
    echo "start_log <name> / stop_log / log_status" | lolcat -f -F 0.2 -p 120 -t
    echo "───────────────────────────────────────────────────────────────" | lolcat -f -F 0.1 -p 100
    
    # Utils section
    printf "   \033[1;33mUtils:\033[0m "
    echo "logs / viewlog / search_logs" | lolcat -f -F 0.2 -p 120 -t
    echo "───────────────────────────────────────────────────────────────" | lolcat -f -F 0.1 -p 150
    
    # Config section
    printf "   \033[1;33mConfig:\033[0m "
    echo "zshconfig" | lolcat -f -F 0.2 -p 120 -t
    echo "───────────────────────────────────────────────────────────────" | lolcat -f -F 0.1 -p 200
    
    # Rclone section
    printf "   \033[1;33mRclone:\033[0m "
    echo "configured with TrueNAS" | lolcat -f -F 0.2 -p 120 -t
    echo "───────────────────────────────────────────────────────────────" | lolcat -f -F 0.1 -p 250
    
    # Safety section
    printf "   \033[1;33mSafety:\033[0m "
    echo "rm -rf protection enabled" | lolcat -f -F 0.2 -p 120 -t
    
    # Bottom separator
    echo "═══════════════════════════════════════════════════════════════" | lolcat -f -F 0.1 -p 300
    echo ""
}

# The money shot alias
alias help='show_help'
# ============================================================================
# PROMPT CUSTOMIZATION
# ============================================================================

# Show privacy mode and logging status in prompt
if [[ $PRIVACY_MODE == 1 ]]; then
    PS1="🙈 $PS1"
elif [[ -n "$CURRENT_LOG" ]]; then
    if [[ "$LOGGING_PAUSED" == "1" ]]; then
        PS1="⏸️📝 $PS1"
    else
        PS1="📝 $PS1"
    fi
fi

# Delayed neofetch (appears after prompt loads)
show_neofetch() {
    neofetch | lolcat
}
# Only show neofetch once per day
if [[ ! -f /tmp/neofetch_shown_$(date +%Y%m%d) ]]; then
    neofetch | lolcat
    touch /tmp/neofetch_shown_$(date +%Y%m%d)
fi