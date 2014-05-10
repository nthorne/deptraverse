#!/bin/bash -

# vim: filetype=sh

# Set IFS explicitly to space-tab-newline to avoid tampering
IFS=' 	
'

# If found, use getconf to constructing a reasonable PATH, otherwise
# we set it manually.
if [[ -x /usr/bin/getconf ]]
then
  PATH=$(/usr/bin/getconf PATH)
else
  PATH=/bin:/usr/bin:/usr/local/bin
fi

HEADER_GLOB="*.h*"

declare -A PARSED


function usage()
{
  cat <<Usage_Heredoc
Usage: $(basename $0) [OPTIONS] [BASE] [PATH]...

BASE is the base folder to search for header files included by
header files in the PATHs

Where valid OPTIONS are:
  -h, --help  display usage

Usage_Heredoc
}

function error()
{
  echo "Error: $@" >&2
  exit 1
}

function parse_options()
{
  while (($#))
  do
    case $1 in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        if [[ -z "$BASE" ]]
        then
          BASE=$1
        else
          parse_headers "$1"
        fi
        ;;
    esac

    shift
  done
}

# If the file name in $1 has not been parsed before, traverse the
# files included by it.
#
# Arguments:
#   $1 - The file to scan
function parse_if_not_parsed()
{
  # Checksum the filename, as slashs cannot be a
  # part of an associative array key.
  local readonly hash=$(echo "$1" | cut -d' ' -f 1 | cksum)

  if [[ -z ${PARSED[$hash]} ]]
  then
    PARSED[$hash]=1
    echo "$1"
    traverse_included "$1"
  fi
}

# Traverse any included file within $1
#
# Arguments:
#   $1 - The file to scan
function traverse_included()
{
  local include
  local path
  local file
  local dependency

  # Scan through include statements
  for include in $(fgrep '#include' "$1" 2>/dev/null | sed -e 's/.*[<"]\([^>"]*\)[>"]/\1/')
  do
    path=$(dirname "$include")
    file=$(basename "$include")

    # if we got a path element, use it to narrow in on dependencies
    if [[ "$include" =~ / ]]
    then
      # only consider files that contain the appropriate path
      for dependency in $(find $BASE -type f -name "$file" 2>/dev/null | fgrep "$path/$file")
      do
        parse_if_not_parsed "$dependency"
      done
    else
      for dependency in $(find $BASE -type f -name "$file" 2>/dev/null)
      do
        parse_if_not_parsed "$dependency"
      done
    fi
  done
}

# Search for header files in $1
#
# Arguments:
#   $1 - The path to search for header files
function parse_headers()
{
  local header

  for header in $(find $1 -type f -name "$HEADER_GLOB")
  do
    parse_if_not_parsed $header
  done  
}


parse_options "$@"
