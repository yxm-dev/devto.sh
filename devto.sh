#! /bin/bash

# DEVTO FUNCTION
    function devto(){
# Includes
    source ${BASH_SOURCE%/*}/pkgfile
    source ${BASH_SOURCE%/*}/files/aliases
## Auxiliary Functions
### get the github repository
        function DEVTO_init_repo(){
            echo "Enter the github repository (user/repo):"
            while :
            do
                read -r -e -p "> " user_repo
                repo=${user_repo##*/}
                user=${user_repo%/*}
                if [[ -n "$user" ]] && [[ -n "$repo" ]]; then
                    REPO=$user_repo
                    break
                else
                    echo "Please, enter user/repo."
                    continue
                fi
            done
        }
### get the branch 
        function DEVTO_init_branch(){
            echo "Enter the repository branch:"
            while :
            do
                read -r -e -p "> " branch
                if [[ -n "$branch" ]]; then
                    BRANCH="$branch"
                    break
                else
                    echo "Please, enter a branch."
                    continue
                fi
            done
        }
### get the dev.to username
        function DEVTO_init_profile(){
            echo "Enter the dev.to username whose account will be connected with the repository $REPO:"
            while :
            do
                read -r -e -p "> " profile
                if [[ -n "$profile" ]]; then
                    PROFILE="$profile"
                    break
                else
                    echo "Please, enter your dev.to username."
                    continue
                fi
            done
        }
### get the dev.to token
         function DEVTO_init_token(){
            echo "Enter the dev.to token for the dev.to profile \"$PROFILE\":"
            while :
            do
                read -r -e -p "> " token
                if [[ -n "$token" ]]; then
                    TOKEN="$token"
                    break
                else
                    echo "Please, enter your token (try \"devto --token\" if you want to know how to get it)."
                    continue
                fi
            done
        }
### get the dev.to directory alias
        function DEVTO_init_alias(){
            echo "Enter an alias (without witespaces) to this dev.to directory:"
            while :
            do
                read -r -e -p "> " alias
                if [[ -n "$alias" ]]; then
                    ALIAS="$alias"
                    break
                else
                    echo "Please, enter a non null alias."
                    continue
                fi
            done

        }
### initiate a directory as a dev.to directory 
        function DEVTO_init(){
            gh_token=$(gh auth token)
            if [[ -z "$gh_token" ]]; then
                echo "error: GitHub CLI was not authenticated. Try \"gh auth\"."
            else
                mkdir files
                cp $PKG_install_dir/files/env .env
                cp $PKG_install_dir/files/gitignore .gitignore
                echo "DEVTO_REPO=$REPO" >> .env
                echo "DEVTO_BRANCH=$BRANCH" >> .env
                echo "DEVTO_PROFILE=$PROFILE" >> .env
                echo "DEVTO_TOKEN=$TOKEN" >> .env
                echo "DEVTO_ALIAS=$ALIAS" >> .env
                echo "DEVTO_ALIAS[$ALIAS]=$PWD" >> $PKG_install_dir/files/aliases
                devto-cli init <<< "$REPO" "$BRANCH" > /dev/null
                rm -r $PWD/posts/article.md
                gh repo create ${REPO##*/} --public
                git remote add dev.to ssh://git@github.com/$REPO
                git add .
                git commit -m "..." > /dev/null
                git checkout -b $BRANCH > /dev/null
                git push -q devto $BRANCH > /dev/null
                gh secret set DEVTO_TOKEN <<< $TOKEN
                echo "Directory \"${PWD##*/}\" was dev.to initialized and syncronized with the GitHub repository \"$REPO\" through the branch \"$BRANCH\", and with your dev.to profile."
                echo "* To refer to this dev.to directory use the alias \"$ALIAS\"."
                echo "* Create a new post with \"devto --new\"."
            fi
        }
### push changes from local dev.to directory to GitHub and dev.to profile
        function DEVTO_push(){
            if [[ -z "$1" ]]; then
                if [[ -f "$PWD/.env" ]] && 
                   [[ -d "$PWD/.git" ]] &&
                   [[ -d "$PWD/.github" ]]; then
                    eval "$(cat $PWD/.env)"
                    git add .
                    git commit -m "..."
                    git push -q dev.to $DEVTO_BRANCH
                    devto-cli p -e
                else
                    echo "error: This is not a dev.to initiated directory."
                fi
            elif [[ "${DEVTO_ALIAS[@]}" =~ "$1" ]]; then
                cd ${DEVTO_ALIAS[$1]}
                eval "$(cat $PWD/.env)"
                git add .
                git commit -m "..." > /dev/null
                git push -q devto $DEVTO_BRANCH > /dev/null
                devto-cli p -e
                cd - > /dev/null
            elif [[ "$1" == "-a" ]]; then
                for i in ${DEVTO_ALIAS[@]}; do
                    DEVTO_push $i
                done
            else
                echo "error: A dev.to initiated directory was not identified."
            fi
        }
### check if a given path contain a given name as a parent directory
        function DEVTO_check_parent(){
            if [[ "$2" == "$(basename "$1")" ]]; then
                return 0
            fi
            parent_dir=$(dirname "$1")
            if [[ "$parent_dir" == "$1" ]]; then
                return 1
            fi
            DEVTO_check_parent "$parent_dir" "$2"
       }
### create a new templated post       
       function DEVTO_new(){
            if [[ -z "$2" ]]; then
                if DEVTO_check_parent "$PWD" "posts"; then
                    if [[ -f "../$PWD/.env" ]] && 
                       [[ -d "../$PWD/.git" ]] &&
                       [[ -d "../$PWD/.github" ]]; then
                        devto-cli new $1
                    else
                        echo "error: This is not a dev.to initiated directory."
                    fi
                else
                    echo "error: This is not a dev.to initiated directory."
                fi
            else
                if [[ "${DEVTO_ALIAS[@]}" =~ "$1" ]]; then
                    cd ${DEVTO_ALIAS[$1]}/posts/$(dirname $2)
                    devto-cli new $(basename $2)
                else
                    echo "error: There is no dev.to initiated directory with alias \"$1\"."
                fi
            fi
        }
### open the dev.to profile in default browser
        function DEVTO_open(){
            if [[ -z "$2" ]]; then
                if DEVTO_check_parent "$PWD" "posts"; then
                    if [[ -f "../$PWD/.env" ]] &&
                       [[ -d "../$PWD/.git" ]] &&
                       [[ -d "../$PWD/.github" ]]; then
                        eval "$(cat $PWD/.env)"
                        xdg-open https://dev.to/$DEVTO_PROFILE & disown
                    else
                        echo "error: This is not a dev.to initiated directory."
                    fi
                else
                    echo "error: This is not a dev.to initiated directory."
                fi
            else
                if [[ "${DEVTO_ALIAS[@]}" =~ "$1" ]]; then
                    eval "$(cat ${DEVTO_ALIAS[$1]}/.env)"
                    xdg-open https://dev.to/$DEVTO_PROFILE & disown
                else
                    echo "error: There is no dev.to initiated directory with alias \"$1\"."
                fi
            fi
        }
### list all dev.to inialized directories with their information
        function DEVTO_list(){
            echo ""            
        }

## DEVTO Function Properly
### without options enter in the interactive mode or print help
        if  [[ -z "$1" ]]; then
            if [[ -f "$PKG_install_dir/files/interactive" ]] &&
               [[ -s "$PKG_install_dir/files/interactive" ]]; then
                sh $PKG_install_dir/files/interactive
            else
                cat $PKG_install_dir/config/help.txt
            fi
### "-c", -"cfg" and "--config" options to enter in the configuration mode
        elif ([[ "$1" == "-c" ]] || 
              [[ "$1" == "-cfg" ]] || 
              [[ "$1" == "--config" ]]) &&
              [[ -z "$2" ]]; then
            if [[ -f "$PKG_install_dir/config/config" ]] &&
               [[ -s "$PKG_install_dir/config/config" ]]; then
                sh $PKG_install_dir/config/config
            else
                echo "None configuration mode defined for the \"devto\" function."
            fi
### "-h" and "--help" options to print help
        elif ([[ "$1" == "-h" ]] || 
              [[ "$1" == "--help" ]]) &&
              [[ -z "$2" ]]; then
            cat $PKG_install_dir/config/help.txt
### "-u" and "--uninstall" options to execute the uninstall script
        elif [[ "$1" == "-u" ]] || [[ "$1" == "--uninstall" ]]; then
            sh  $PKG_install_dir/install/uninstall
### "-i"  and "--init" to dev.to initiate the working directory
        elif [[ "$1" == "-i" ]] || [[ "$1" == "--init" ]]; then
            DEVTO_init_repo
            DEVTO_init_branch
            DEVTO_init_profile
            DEVTO_init_token
            DEVTO_init_alias
            DEVTO_init
### "-p" and "--push" to push a dev.to initiated directory
        elif [[ "$1" == "-p" ]] || [[ "$1" == "--push" ]]; then
            DEVTO_push $2
### "-n" and "--new" to create a new templated article
        elif [[ "$1" == "-n" ]] || [[ "$1" == "--new" ]]; then
            DEVTO_new $2 $3
### "-o" and "--open" to open the dev.to profile in a browser
        elif [[ "$1" == "-o" ]] || [[ "$1" == "--open" ]]; then
            DEVTO_open $2 $3
### "-t" and "--token" to explain how to get a token
        elif [[ "$1" == "-t" ]] || [[ "$1" == "--token" ]]; then
            cat $PKG_install_dir/config/token.txt
### if given a valid alias, move to the corresponding dev.to dir
        elif [[ "${DEVTO_ALIAS[@]}" =~ "$1" ]]; then
            cd ${DEVTO_ALIAS[$1]}
### else
        else 
            echo "Option not defined for the \"devto\" function."
        fi
## Unseting Auxiliary Functions
    unset -f DEVTO_init_repo
    unset -f DEVTO_init_alias
    unset -f DEVTO_init_branch
    unset -f DEVTO_init_profile
    unset -f DEVTO_init_token
    unset -f DEVTO_init
    unset -f DEVTO_push
    unset -f DEVTO_new
    unset -f DEVTO_open
    }
 
# ALIASES
alias devtoi="devto -i"
alias devton="devto -n"
alias devtop="devto -p"
alias devtoo="devto -o"
alias devtot="devto -t"
alias devtoh="devto -h"
