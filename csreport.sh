#!/bin/sh

QUIET=0
SHORT=0
FILELIST=
while getopts "qsf:" opt; do
    case "$opt" in
    q)
        QUIET=1
        ;;
    s)
        SHORT=1
        ;;
    f)
        FILELIST=$OPTARG
        ;;
    esac
done

if [ "$FILELIST" = '' ]
then
  #Read from STDIN
  FILELIST=`mktemp`
  cp /proc/${$}/fd/0 $FILELIST
fi

FILTEREDLIST=`mktemp`
for fileName in $(cat $FILELIST)
do
  if [ -f $fileName ]
  then
    echo $fileName >> $FILTEREDLIST
  fi
done

filecount=`wc -l $FILTEREDLIST | awk '{print $1}'`
TMPFILE2=`mktemp`
tr -s '\n' '\000' < $FILTEREDLIST > $TMPFILE2
linecount=`wc -l --files0-from=$TMPFILE2 | tail -n 1 | awk '{print $1}'`
if [ "$linecount" = "" ]
then
    linecount="0"
fi
errtot=0
wrntot=0
filcnt=0
proccnt=0;
for file in `cat $FILTEREDLIST`; do
    proccnt=$(($proccnt + 1))
    if [ $QUIET = 0 ]
    then
      echo "processing $proccnt of $filecount" 1>&2
    fi
    result=`phpcs --standard=DWS --report=summary $file | grep "^A TOTAL"`
    if [ ! -z "$result" ]; then
        errcnt=`echo $result | awk '{print $4}'`
        wrncnt=`echo $result | awk '{print $7}'`
        filcnt=$(($filcnt + 1))
        errtot=`expr $errcnt + $errtot`
        wrntot=`expr $wrncnt + $wrntot`
    fi
done
if [ $SHORT = 0 ]
then
  echo "Total Files: $filecount"
  echo "Total Lines: $linecount"
  echo "Files with problems: $filcnt"
  echo "Errors: $errtot"
  echo "Warnings: $wrntot"
else
  echo "$filecount $linecount $filcnt $errtot $wrntot"
fi

rm $TMPFILE2
