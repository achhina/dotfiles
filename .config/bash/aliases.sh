##### Editors #####

alias v="nvim"
alias vi="nvim" 

##### Multiplexers #####

alias t="tmux"

##### Python #####

alias pip="python3 -m pip"
alias pip3="pip"

##### Shell Utils #####

# exa - https://the.exa.website/
if where exa &> /dev/null; then
    alias ls="exa --header"
    alias lst="exa --tree"
    alias lsg="exa --header --long --git"
fi

##### Custom #####

# Manage dotfiles with bare clone
alias config="/usr/bin/git --git-dir=${HOME}/.cfg/ --work-tree=${HOME}"
