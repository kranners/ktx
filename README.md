# ktx

Instead of `EXPORT`ing your kubeconfigs every goddamn time, use a script instead!
I recommend you add an alias to your ~/.bashrc ( or ~/.zshrc ) to run this script.

## Flags
- -h Show these flags
- -d Start dashboard instead of shell
- -t Copy a token if one is present
- -D <name> delete a listing
- -a Add new kubeconfig to list!

The following flags are related to **add mode only**
- -r raw input instead of file location
- -f Relative location of kubeconfig file
- -T Relative location of token file (just the token! no 'token:')
- -n Name of entry in list
