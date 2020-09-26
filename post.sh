#!/bin/bash

usage() {
	echo "Usage:"
    echo "  test.sh [-j JAVA_DIR] [-m MAVEN_DIR]"
    echo "Description:"
    echo "    JAVA_DIR, the path of java."
    echo "    MAVEN_DIR, the path of maven."
    exit -1
}

upload="false"

while getopts 'h:t:m:t' OPT; do
    case $OPT in
        j) JAVA_DIR="$OPTARG";;
        m) MAVEN_DIR="$OPTARG";;
        u) upload="true";;
        h) usage;;
        ?) usage;;
    esac
done

echo $JAVA_DIR
echo $MAVEN_DIR
echo $upload



