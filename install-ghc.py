#!/usr/bin/env python

import subprocess
import sys
import os

stack_root, rpm_build_root, dest_path = sys.argv[1:4]

fullname = None
d = os.path.join(stack_root, "programs", "x86_64-linux")
for filename in os.listdir(d):
    if '.tar.' in filename:
        fullname = os.path.join(d, filename)
        break

extracted = "EXTRACTED"
if fullname and not os.path.exists(extracted):
    os.mkdir(extracted)
    subprocess.check_output(["tar", "-C", extracted, "-xf", fullname])

os.chdir(os.path.join(extracted, os.listdir(extracted)[0]))
cmd = ["./configure", "--prefix", dest_path]
print cmd
print subprocess.check_output(cmd)
cmd = ["make", "DESTDIR=" + rpm_build_root, "install"]
print cmd
print subprocess.check_output(cmd)

installed_bins = os.path.join(rpm_build_root,
                              os.path.join(dest_path[1:], "bin"))
stackage_dist_bin = os.path.join(rpm_build_root,
                                 os.path.dirname(dest_path)[1:], "bin")

if not os.path.exists(stackage_dist_bin):
    os.mkdir(stackage_dist_bin)
for installed_bin in os.listdir(installed_bins):
    src = os.path.join("..", "ghc", "bin", installed_bin)
    dest = os.path.join(stackage_dist_bin, installed_bin)
    print (src, dest)
    os.symlink(src, dest)
