#!/bin/bash
##
 # New Magento Demo Site Script
 #
 # @author     Rob Tull <rob@classyllama.com>
 # @copyright  Copyright (c) 2014 by Rob Tull
 #
 # @TODO - add with flag for whether to remove git
 # @TODO - add flag to just refresh sample data
 ##

WORK_DIR=$(pwd)

MAGE_ARCHIVE='magento.tgz'
SAMPLE_ARCHIVE='sample_data.tgz'

TAR_DIR=$(tar -tf $MAGE_ARCHIVE | grep -o '^[^/.]\+' | sort -u)
INSTALL_DIR='htdocs'
SAMPLE_DIR='sample_data'
PATCH_DIR='patch'

# Things to drop when cleaning
CLEAN_FILES[0]='.gitignore'
CLEAN_FILES[1]='composer.lock'
CLEAN_FILES[2]='install-progress'

CLEAN_DIRS[0]=$INSTALL_DIR
CLEAN_DIRS[1]='.git'
CLEAN_DIRS[2]='resources'
CLEAN_DIRS[3]='vendor'

git_init() {
    echo 'Initialize empty Git repo...'
    git init
    git config core.fileMode false
}

clean_install() {
    # Drop current codebase
    echo 'Cleaning any current Magento installation...'

    for DIR in "${CLEAN_DIRS[@]}"
    do
        if [ -d $DIR ]; then
            echo "Removing $DIR"
            sudo rm -rf $WORK_DIR/$DIR
        fi
    done

    for FILE in "${CLEAN_FILES[@]}"
    do
        if [ -f $FILE ]; then
            echo "Removing $FILE"
            sudo rm $WORK_DIR/$FILE
        fi
    done
}

mage_install() {
    if [ -f 'magento.tgz' ]; then
        if [ -f 'composer.json' ]; then
            # Run Composer install when file is found
            echo 'Running Composer Install...'

            cp $MAGE_ARCHIVE mage.bak

            git_init

            echo '*** BEGIN COMPOSER OUTPUT ***'
            composer install
            if [ -f 'install-progress' ]; then
                echo '*** COMPOSER FAILED - ABORTING ***'
                exit
            fi
            echo '*** END COMPOSER OUTPUT ***'

            mv mage.bak $MAGE_ARCHIVE
        else
            # Extract Magento code
            echo 'Extracting Magento...'
            tar -xzf $MAGE_ARCHIVE

            # Move extracted code into htdocs directory if not already there
            if ! [ -d $WORK_DIR/$INSTALL_DIR]; then
                mv $WORK_DIR/$TAR_DIR $WORK_DIR/$INSTALL_DIR
            fi
        fi
    else
        echo 'Magento install package not found!!'
        echo 'ABORTING'
        exit
    fi
}

clean_install

mage_install

if [ -f $WORK_DIR/$SAMPLE_ARCHIVE ] || [ -d $WORK_DIR/$SAMPLE_DIR ]; then
    echo 'Installing sample data...'

    if ! [ -d $WORK_DIR/$SAMPLE_DIR ]; then
        SAMPLE_EXTRACT=true;

        # Extract sample data
        echo 'Extracting sample data...'
        mkdir $WORK_DIR/$SAMPLE_DIR
        cp $WORK_DIR/$SAMPLE_ARCHIVE $WORK_DIR/$SAMPLE_DIR/
        tar -xzf $WORK_DIR/$SAMPLE_DIR/$SAMPLE_ARCHIVE -C $WORK_DIR/$SAMPLE_DIR/
    fi

    # Find sample data SQL file
    SQL_FILEPATH=$(find ./$SAMPLE_DIR -type f -name *.sql)

    if [ $SQL_FILEPATH ] && [ -f $SQL_FILEPATH ]; then
        # Set sample data directory path
        SAMPLE_CONTENT=$(dirname $SQL_FILEPATH)

        # Add media to Magento installation
        if [ -d $SAMPLE_CONTENT/media ]; then
            echo 'Add sample media to Magento installation...'
            rsync -a $SAMPLE_CONTENT/media/ $WORK_DIR/$INSTALL_DIR/media/
        else
            echo '*** SAMPLE MEDIA NOT FOUND!!! ***'
        fi

        if [ -d "$SAMPLE_CONTENT/privatesales" ]; then
            cp -R $SAMPLE_CONTENT/privatesales $WORK_DIR/$INSTALL_DIR/
        fi

        # Request database name for data installation
        echo 'Installing sample database...'
        read -p 'Enter database name: ' DBNAME

        # Perform database setup
        echo "Creating fresh Magento sample database $DBNAME..."

        # Connect to MySQL
        mysql -hlocalhost -uroot -proot << EOF_SQL

            # Drop existing database if exists
            DROP DATABASE IF EXISTS \`$DBNAME\`;
            CREATE DATABASE \`$DBNAME\`
                DEFAULT CHARACTER SET utf8
                DEFAULT COLLATE utf8_general_ci;

            # Install sample data
            use \`$DBNAME\`;
            source $SQL_FILEPATH;

EOF_SQL
    else
        echo '*** SAMPLE DATA SQL FILE NOT FOUND!!! ***'
        echo 'Aborting sample data installation...'
    fi

    if [ $SAMPLE_EXTRACT=true ]; then
        # Cleaning up...
        echo 'Cleaning up sample data...'
        rm -rf $WORK_DIR/$SAMPLE_DIR
    fi
fi

# Apply any patches to the Magento installation
if [ -d "$PATCH_DIR" ]; then
    echo 'Moving patch files into Magento installation...'
    rsync -a $PATCH_DIR/ $INSTALL_DIR/
fi

# Set permissions on Magento installation
chmod -R 777 $WORK_DIR/$INSTALL_DIR

echo 'All Done!! Now run the installer, Sparky!'
