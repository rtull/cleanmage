# Script for Clean Magento Installs

As an exercise in shell scripting (I'm a shell script n00b) and to save myself time creating fresh Magento demo instances, I've created this little script to automate the process of creating/re-creating fresh Magento installs (optionally with Magento sample data).

It's pretty simple:

1. Create the directory where you want Magento to live
2. **cd** into the directory you just created
3. Add a tarball containing the Magento codebase you wish to install named "magento.tgz"
4. (Optionally) Add a tarball containing the sample date you wish to install named "sample_data.tgz"
5. Run cleanmage
6. Do what cleanmage says

This script makes a lot of assumptions since I wrote it for my own personal use. It is free to use however you like. I make no promises of any kind about this scripts capabilities or fitness for any application.

## Some Additional Things...

* This script assumes you have a MySQL server accessible at **localhost** with the credentials **root/root**.
    * I might refactor this to ask for creds - no promises.
* Once you provide a DB name to the script, it will destroy any existing DB with that name, so be careful.
* Sets the permission of the Magento install to 777 for easy local file manipulations. This would not be wise in a productions environment...
* If you have any files to patch into Magento, you can place them in a **patch/** directory with the appropriate subdirectories to match the Magento structure. These files will be added to the Magento installation.
