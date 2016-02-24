#!/usr/bin/env python

import subprocess
import sys
import os

pathname, stack_root, stackage_root_installed = sys.argv[1:4]

try:
    installed_path = os.path.join(stackage_root_installed, "snapshots", pathname)
    if os.path.exists(installed_path):
        if os.path.isdir(pathname):
            try:
                os.rmdir(pathname)
            except OSError, e:
                pass
        else:
            print "Removing %s that is already installed as %s" % (pathname, installed_path)
            os.unlink(pathname)
    else:
        if pathname.endswith('.so') or os.path.basename(os.path.dirname(pathname)) == "bin":
            print "Fixing rpath in %s" % (pathname, )
            rpath = subprocess.check_output(["chrpath", pathname]).strip()
            new_rpath = rpath.split(pathname + ": RPATH=")[1].replace(stack_root, stackage_root_installed)
            subprocess.check_output(["chrpath", pathname, "--replace", new_rpath])
except OSError, e:
    print e
except subprocess.CalledProcessError, e:
    print e
