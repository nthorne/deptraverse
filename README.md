deptraverse
===========

Tiny script to recursively traverse C/C++ header dependencies.

usage
=====

$ deptraverse BASE PATH [...]

This will search through each PATH folder for files matching *.h*,
and for each include statement in every matching file, BASE will
be searched for that dependency, and every one of those matches
will in turn be searched recursively until all dependencies has
been determined.

Please note that this script does not consider comments and/or
preprocessor directives.
