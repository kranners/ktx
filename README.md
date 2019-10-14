# ktx

Instead of `EXPORT`ing your kubeconfigs every goddamn time, use a script instead!
I recommend you add an alias to your ~/.bashrc ( or ~/.zshrc ) to run this script.

Usage:  
ktx [add | del | sel] [filename] [--name context-name]  
Running with no arguments will open the selector menu  
- **add** - adds a listing  
    - ```ktx add <filename>```  
    - ```ktx add <filename> --name <context-name>```  
- **del** - deletes a listing  
    - ```ktx del <context-name>```  
- **tldr** - prints the TLDR   
    - ```ktx tldr```  
