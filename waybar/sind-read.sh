#!/bin/bash

FILE=/tmp/indicators.json

# Remove all but the latest sind-read process.
pgrep -f "$0" | head -n-1 | xargs kill

# Enable "strict mode"
set -eu

# Read the indicators and output a waybar-compatible message
PROCESS() {
	  DATA=$(cat "$FILE" || true)
	  if [ -z "$DATA" ];then
		 continue
	  fi
	  
	  # This might look tricky, but thisjust reads the values and outputs an 
	  # HMTL-like list of tags (these tags help to add the color).
	  text=""
	  for key in $(echo "$DATA" | jq 'keys' |grep '^  "'|cut -d\" -f2);do
				 value=$(echo "$DATA"| jq -r ".$key")
				 text="$text<span foreground='#000' background='$value'> $key </span>"
			  done

      # After we're done, just wrap it in JSON
	  result="{\"text\": \"$text\", \"class\":\"\", \"tooltip\":\"\"}"
	  echo "$result"
}

# Make sure the indicators file exists
if [ ! -f "$FILE" ];then
   echo "{}" > "$FILE"
fi

# Main: After processing the indicators once, wait for changes on it and repeat
PROCESS
inotifywait -m -e close_write "$FILE" | while read _ ;do
      PROCESS										 
done
