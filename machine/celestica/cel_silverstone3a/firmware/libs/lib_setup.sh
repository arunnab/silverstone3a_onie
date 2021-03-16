#!/bin/sh

echo "setting up essential libs infra"

cur_dir=$(pwd)
cd $cur_dir/libs
pwd


mkdir -p /lib/x86_64-linux-gnu
cp libc-2.19.so libdl-2.19.so /lib/x86_64-linux-gnu
cd /lib/x86_64-linux-gnu
ln -sf libc-2.19.so libc.so.6
ln -sf libdl-2.19.so libdl.so.2
cd - > /dev/null

#mkdir -p /usr/lib/x86_64-linux-gnu
#cp libxml2.so.2.9.1 libstdc++.so.6.0.20 libcrypto.so.1.0.0 /usr/lib/x86_64-linux-gnu
#cd /usr/lib/x86_64-linux-gnu
#ln -sf libxml2.so.2.9.1 libxml2.so.2
#ln -sf libstdc++.so.6.0.20 libstdc++.so.6
#cd - > /dev/null


mkdir -p /lib64
cp ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 

echo "essential libs infra is done."
