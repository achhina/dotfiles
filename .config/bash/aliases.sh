##### Editors #####

alias v="nvim"
alias vi="nvim" 

##### Multiplexers #####

alias t="tmux"
alias ta="tmux attach"

##### Python #####

alias pip="python3 -m pip"
alias pip3="pip"

##### Shell Utils #####

# exa - https://the.exa.website/
if where exa &> /dev/null; then
    function exa_lst {
        exa --tree --all --level ${1:-1}
    }

    alias ls="exa --header --all"
    alias lst="exa_lst"
    alias lsg="exa --header --all --long --git"
fi

##### Custom #####

# Manage dotfiles with bare clone
alias config="/usr/bin/git --git-dir=${HOME}/.cfg/ --work-tree=${HOME}"
