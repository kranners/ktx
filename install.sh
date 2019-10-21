shellname=$(echo $SHELL | grep -Eo "[A-Za-z]+" | tail -1)
rcfile="$HOME/.$shellname"rc

matches=$(grep -cim1 "ktx" "$rcfile")

if [ ! $matches -eq 0 ]; then
    echo "The script is already installed! Refresh your shell."
else

    # write this to your bashrc / zshrc
    # I know this can be done with cat EOF! It just doesnt work for very literal things like this
    echo "ktx() {" >> $rcfile
    echo "    sh $PWD/ktx.sh" >> $rcfile
    echo "    conf=\$(cat $HOME/.kubeconfigs/current)" >> $rcfile
    echo "    export KUBECONFIG="\$conf"" >> $rcfile
    echo "}" >> $rcfile

    echo "Installed! Please refresh your shell."
fi

