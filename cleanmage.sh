#!/bin/bash
##
 # New Magento Demo Site Script
 #
 # @author     Rob Tull <rob@classyllama.com>
 # @copyright  Copyright (c) 2014 by Rob Tull
 ##

MAGE_DIR=`pwd`
TAR_DIR=`tar -tf magento.tgz | grep -o '^[^/]\+' | sort -u`

if [ -d "htdocs" ]; then
    # Drop current codebase
    echo "Removing current Magento installation..."
    rm -r $MAGE_DIR/htdocs
fi

# Extract Magento code
echo "Extracting Magento..."
tar -xzf magento.tgz
mv $MAGE_DIR/$TAR_DIR $MAGE_DIR/htdocs

if [ -f $MAGE_DIR/sample_data.tgz ]; then
    # Extract sample data
    echo "Extracting sample data..."
    mkdir $MAGE_DIR/sample_data
    cp $MAGE_DIR/sample_data.tgz $MAGE_DIR/sample_data/
    tar -xzf $MAGE_DIR/sample_data/sample_data.tgz -C $MAGE_DIR/sample_data/

    # Set sample date paths
    SQL_FILEPATH="`find ./sample_data -type f -name *.sql`"
    SAMPLE_DIR="`dirname $SQL_FILEPATH`"

    # Add media to Magento installation
    echo "Add sample media to Magento installation..."
    rsync -a $SAMPLE_DIR/media/ $MAGE_DIR/htdocs/media/

    if [ -d "$SAMPLE_DIR/privatesales" ]; then
        cp -R $SAMPLE_DIR/privatesales $MAGE_DIR/htdocs/
    fi

    # Request database name for data installation
    echo "Installing sample data..."
    read -p "Enter database name: " DBNAME

    # Connect to MySQL
    mysql -hlocalhost -uroot -proot << EOF_SQL
    
        # Drop existing database if exists
        DROP DATABASE IF EXISTS $DBNAME;
        CREATE DATABASE $DBNAME
            DEFAULT CHARACTER SET utf8
            DEFAULT COLLATE utf8_general_ci;
    
        # Install sample data
        use $DBNAME;
        source $SQL_FILEPATH;
    
EOF_SQL

    # Cleaning up...
    echo "Cleaning up sample data..."
    rm -r $MAGE_DIR/sample_data
fi

# Apply any patches to the Magento installation
if [ -d "patch" ]; then
    echo "Moving patch files into Magento installation..."
    rsync -a patch/ htdocs/
fi

# Set permissions on Magento installation
chmod -R 777 $MAGE_DIR/htdocs

echo "All Done!! Now run the installer, Sparky!"
