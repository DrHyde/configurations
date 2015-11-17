#!/bin/sh

cd ~/.cpandistprefs

for i in bytemark pigsty ; do
  ssh $i "cd .cpandistprefs;git pull;./rebuild.sh"
done
