# Global Copilot instructions

Apply these preferences in all repositories unless explicitly told otherwise.

## Directories

If you need temporary storage, create a tmp/ directory in the root of the current repository and add it to .gitignore.

Do not use /tmp.

In any tool from outside the repository that you need to run always use absolute paths instead of relative paths unless
you have no choice. For example

* Bad: `mkdir subdir;cd subdir; do-something; cd ..
* Good: Assuming that you are in /Users/david/wibble/boing ... `mkdir subdir; cd subdir; do-something; cd /Users/david/wibble/boing`
* Best: `mkdir subdir; ( cd subdir; do-something )` in a subshell

## Third-party libraries

When using third-party libraries and multiple libraries are available prepare a brief summary of each with pros and cons, say which one you prefer and why, and ask me to choose. Always provide the option of writing your own version.
