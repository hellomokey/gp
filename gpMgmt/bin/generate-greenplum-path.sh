#!/bin/bash

if [ x$1 != x ] ; then
    GPHOME_PATH=$1
else
    GPHOME_PATH="\`pwd\`"
fi

if [ "$2" = "ISO" ] ; then
	cat <<-EOF
		if [ "\${BASH_SOURCE:0:1}" == "/" ]
		then
		    GPHOME=\`dirname "\$BASH_SOURCE"\`
		else
		    GPHOME=\`pwd\`/\`dirname "\$BASH_SOURCE"\`
		fi
	EOF
else
	cat <<-EOF
		GPHOME=${GPHOME_PATH}
	EOF
fi


PLAT=`uname -s`
if [ $? -ne 0 ] ; then
    echo "Error executing uname -s"
    exit 1
fi

cat << EOF

# Replace with symlink path if it is present and correct
if [ -h \${GPHOME}/../greenplum-db ]; then
    GPHOME_BY_SYMLINK=\`(cd \${GPHOME}/../greenplum-db/ && pwd -P)\`
    if [ x"\${GPHOME_BY_SYMLINK}" = x"\${GPHOME}" ]; then
        GPHOME=\`(cd \${GPHOME}/../greenplum-db/ && pwd -L)\`/.
    fi
    unset GPHOME_BY_SYMLINK
fi
EOF

cat <<EOF
#setup PYTHONHOME
if [ -x \$GPHOME/ext/python/bin/python ]; then
    PYTHONHOME="\$GPHOME/ext/python"
fi
EOF

#setup PYTHONPATH
if [ "x${PYTHONPATH}" == "x" ]; then
    PYTHONPATH="\$GPHOME/lib/python"
else
    PYTHONPATH="\$GPHOME/lib/python:${PYTHONPATH}"
fi
cat <<EOF
PYTHONPATH=${PYTHONPATH}
EOF

GP_BIN_PATH=\$GPHOME/bin
GP_LIB_PATH=\$GPHOME/lib

if [ -n "$PYTHONHOME" ]; then
    GP_BIN_PATH=${GP_BIN_PATH}:\$PYTHONHOME/bin
    GP_LIB_PATH=${GP_LIB_PATH}:\$PYTHONHOME/lib
fi
cat <<EOF
PATH=${GP_BIN_PATH}:\$PATH
EOF

cat <<EOF
LD_LIBRARY_PATH=${GP_LIB_PATH}:\${LD_LIBRARY_PATH-}
export LD_LIBRARY_PATH
EOF

# openssl configuration file path
cat <<EOF
OPENSSL_CONF=\$GPHOME/etc/openssl.cnf
EOF

cat <<EOF
export GPHOME
export PATH
EOF

cat <<EOF
export PYTHONPATH
export PYTHONHOME
EOF

cat <<EOF
export OPENSSL_CONF
EOF
