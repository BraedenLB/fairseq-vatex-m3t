#!/bin/bash

FV=$(pwd)
RAW=$FV/vatex/raw

function dw_all {
	echo "Downloading all VaTeX Videos"
	
	local SEEN=0
	local ERR=0

	set -e
	input="${RAW}/*.ids"
	while read l; do 
	  
	  
	  IFS='_' read -r -a ARR
	  
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN}))
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  echo "Starting Download ${SEEN}"
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy -quiet || true; let ERR++
	  if [[ $CHECK -eq $ERR ]]; then
	  	let SEEN++
		echo "Successfully Downloaded ${SEEN} Videos"
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

function dw_select {
	echo "Downloading ${1} VaTeX Videos"
	
	local NUM=$1
	local ERR=0
	local SEEN=0
	
	set -e
	input="${RAW}/*.ids"
	while IFS='_' read -r -a ARR; do 
	  if [[ $SEEN -ge $NUM ]]; then
	  	break
	  fi
	  
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN})) 
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  echo "Starting Download ${SEEN}"
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy || true; let ERR++
	  
	  if [[ $CHECK -eq $ERR ]]; then
	  	let SEEN++
		echo "Successfully Downloaded ${SEEN} Videos"
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

function download_all {
	for FILE in "$RAW"/*.ids; do 
		echo "remove later"	
	done
}

function download_select {
	echo "Downloading ${1} videos"
	MAX=$1
	SEEN=0
	ERR=0
	for FILE in "$RAW"/*.ids; do
		ERR=0
		while read -r L; do
			#if the given number of videos has been downloaded, break loop
			if [[ $SEEN -ge $MAX ]]; then 
				echo "Seen a Maximum of ${SEEN} Lines"
				break
			fi
			
			#set the string delimiter to "_" to break up each line into an array
			IFS="_" read -r -a ARR <<< $L
			
			ID=${ARR[0]} #video ID
			
			#set clip start time
			if [[ "${ARR[1]}" =~ [1-9] ]]; then
				#If clip start time > 0, trip padded 0s
				I
				IN=${ARR[1]#"${ARR[1]%%[!0]*}"}
			else
				#If clip start time == 0, set input to 0
				IN=0
			fi
			
			if [[ "${ARR[2]}" =~ [1-9] ]]; then
	  			#If clip end time > 0, trip padded 0s
				OUT=${ARR[2]#"${ARR[2]%%[!0]*}"} 			
			else 
				#If clip end time == 0, set input to 0
				OUT=0
			fi
			
			#clip duration is clip end time - clip start time
	 	 	LN=$((${OUT}-${IN}))
			
			#for every video, download from given timeframe
			CHECK=$ERR			
			echo "Starting Download ${ID}: ${SEEN}/${MAX}"
			#access whole video with youtube-dl
			#reencode and save selected clip with ffmpeg
			#if the download doesn't complete or an error is returned, skip and increment error count
			ffmpeg -ss $IN -t $LN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -vcodec copy "${ARR[0]}.mp4" || true; let ERR++
			
			#if the video successfully downloads (i.e. the error count hasn't been incremented), 
			#increment the number of successful videos
			if [[ $CHECK -eq $ERR ]]; then
				let SEEN++
				echo "Successfully Downloaded Video ${ARR[0]}"
			fi
			
		done < $FILE
		echo "--Videos Downloaded in ${FILE}: ${SEEN}"
		echo "--Videos Skipped in ${FILE}: ${ERR}"
	done
}

if [ -z $1 ]; then
	#dw_all
	test $1
else
	download_select $1
fi
