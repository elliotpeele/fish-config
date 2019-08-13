set -gx HOSTNAME (hostname -f)
set SSH_ENV $HOME/.ssh/environment.$HOSTNAME
set SSH_SOCK /var/tmp/elliot-ssh/socket.$HOSTNAME

function start_agent
    # echo "Initializing new SSH agent ..."
    ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
    # echo "succeeded"
    relink_ssh_sock
    ssh-add
end

function test_identities
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $status -eq 0 ]
        ssh-add
        if [ $status -eq 2 ]
            start_agent
        end
    end
end

function relink_ssh_sock
    # echo "relinking ssh sock $SSH_AUTH_SOCK"
    if [ "$SSH_AUTH_SOCK" = "$SSH_SOCK" ]
        # echo "SSH_AUTH_SOCK already set to SSH_SOCK"
        return
    end
    set SSH_SOCK_DIR (dirname $SSH_SOCK)
    if [ ! -d $SSH_SOCK_DIR ]
        mkdir -p $SSH_SOCK_DIR
    else
        rm -f $SSH_SOCK
    end
    chmod 700 $SSH_SOCK_DIR
    ln -s $SSH_AUTH_SOCK $SSH_SOCK
    set -gx SSH_AUTH_SOCK $SSH_SOCK
end

function tmux -a cmd -d "Wraps tmux to provide updatenv command"
    if test -z $cmd
        command tmux
    else
        switch $cmd
            case "updatenv"
                for var in (command tmux showenv)
                    switch $var
                        case '-*'
                            set -e (echo $var | sed 's/-//')
                        case '*' 
                            eval set -x (echo $var | sed 's/=/ "/' | sed 's/$/"/')
                    end
                end
            case "*" 
                command tmux $argv
        end
    end
end

if [ ! -n "$SSH_AUTH_SOCK" ]
    #    echo "no auth sock found"
    if [ -L "$SSH_SOCK" and -e (readlink $SSH_SOCK) ]
        echo "using $SSH_SOCK"
        set -gx SSH_AUTH_SOCK $SSH_SOCK
    end
else
    relink_ssh_sock
end

function goenv
    setenv GOPATH $argv[1]
    setenv GO111MODULE on
    set -gx PATH $GOPATH/bin:$PATH
end

# Setup locale since the system doesn't provide initialization
set -gx LANG en_US.UTF-8
set -gx LC_CTYPE en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# Make sure my bin dir is first
set -gx PATH $HOME/bin /sbin /usr/sbin $PATH
set -gx CVS_RSH ssh
set -gx PYTHONSTARTUP $HOME/git/fish-config/pystartup

#export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}: ${PWD/#$HOME/~}\007"'

set -gx JAVA_HOME /usr/lib/jvm/jre

# load solarized colors
. $HOME/git/fish-config/solarized.fish
. $HOME/git/fish-config/colors.fish

set -gx GOROOT $HOME/dist/go
set -gx PATH $GOROOT/bin $PATH

set -gx EDITOR /bin/vim
