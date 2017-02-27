#!/bin/bash
#
# Usage:
#    tools/warnings.sh [node]
# Output: for each node outputs its warnings and the number of times that
# warning has ocurred. If the argument node is specified, it only shows
# the warnings of that node.
# Examples: tools/warnings.sh
#           tools/warnings.sh 000a
# Environmental variables:
# CHUTNEY_WARNINGS_IGNORE_EXPECTED: set to "true" to filter expected warnings
# CHUTNEY_WARNINGS_SUMMARY: set to "true" to merge warnings from all instances

if [ ! -d "$CHUTNEY_PATH" -o ! -x "$CHUTNEY_PATH/chutney" ]; then
    # looks like a broken path: use the path to this tool instead
    TOOLS_PATH=`dirname "$0"`
    export CHUTNEY_PATH=`dirname "$TOOLS_PATH"`
fi
if [ -d "$PWD/$CHUTNEY_PATH" -a -x "$PWD/$CHUTNEY_PATH/chutney" ]; then
    # looks like a relative path: make chutney path absolute
    export CHUTNEY_PATH="$PWD/$CHUTNEY_PATH"
fi

function show_warnings() {
    if [ "$CHUTNEY_WARNINGS_SUMMARY" = true ]; then
        echo "${GREEN}All `basename $1`:${NC}"
        FILE="$1/*/$LOG_FILE"
    else
        echo "${GREEN}Node `basename $1`:${NC}"
        FILE="$1/$LOG_FILE"
    fi
    if [ "$CHUTNEY_WARNINGS_IGNORE_EXPECTED" = true -a \
        -e "$IGNORE_FILE" ]; then
        CAT="grep -v -f"
        echo " ${GREEN}(Ignoring expected warnings, run chutney/tools/warnings.sh to see all warnings)${NC}"
    else
        CAT=cat
        IGNORE_FILE=
    fi
    # Label errs as "Warning:", they're infrequent enough it doesn't matter
    $CAT $IGNORE_FILE $FILE | \
    sed -n -E 's/^.*\[(warn|err)\]//p' | sort | uniq -c | \
    sed -e 's/^\s*//' -e "s/ *\([0-9][0-9]*\) *\(.*\)/ ${YELLOW}Warning:${NC} \2${YELLOW} Number: \1${NC}/"
    if [ "$CHUTNEY_WARNINGS_SUMMARY" != true ]; then
        echo ""
    fi
}

function usage() {
    echo "Usage: $NAME [node]"
    exit 1
}

# Don't colour in log files
if [ -t 1 ]; then
    NC=$(tput sgr0)
    YELLOW=$(tput setaf 3)
    GREEN=$(tput setaf 2)
fi
CHUTNEY="$CHUTNEY_PATH/chutney"
NAME=$(basename "$0")
DEST="$CHUTNEY_PATH/net/nodes"
LOG_FILE=info.log
# ignore warnings we expect to get every time chutney runs
CHUTNEY_WARNINGS_IGNORE_EXPECTED=${CHUTNEY_WARNINGS_IGNORE_EXPECTED:-0}
# don't put spaces in CHUTNEY_PATH or IGNORE_FILE
IGNORE_FILE="$CHUTNEY_PATH/tools/ignore.warnings"
# merge all log files into one before counting entries
CHUTNEY_WARNINGS_SUMMARY=${CHUTNEY_WARNINGS_SUMMARY:-0}

[ -d "$DEST" ] || { echo "$NAME: no logs available"; exit 1; }
if [ $# -eq 0 ];
then
    if [ "$CHUTNEY_WARNINGS_SUMMARY" = true ]; then
        show_warnings "$DEST"
        exit 0
    fi
    for dir in "$DEST"/*;
    do
        [ -e "${dir}/$LOG_FILE" ] || continue
        show_warnings "$dir"
    done
elif [ $# -eq 1 ];
then
    [ -e "$DEST/$1/$LOG_FILE" ] || \
        { echo "$NAME: no log available"; exit 1; }
    show_warnings "$DEST/$1"
else
    usage
fi
