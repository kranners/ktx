# ktx

Instead of `EXPORT`ing your kubeconfigs every goddamn time, use a script instead!
I recommend you add an alias to your ~/.bashrc ( or ~/.zshrc ) to run this script.

Usage: 
ktx [add | del | sel] [<filename>] [--token <plain token file>] [--name <context-name>]
Running with no arguments will open the selector menu
add - adds a listing
    eg. ktx add <filename>
        ktx add <filename> --token <tokenfile> 
        ktx add <filename> --token <tokenfile> --name <context-name>
del - deletes a listing
    eg. ktx del <context-name>
sel - select a listing
    eg. ktx sel <context-name>
tldr - prints the TLDR 
    eg. ktx tldr
help - prints this 
        eg. ktx help
