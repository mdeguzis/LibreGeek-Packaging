#!/bin/bash

# PostProcessing Script for MPV
# Author: Jeremy
# http://www.ezoden.com/htpc-linux/55/how-to-setup-htpc-linux-introduction


#########################################
# USER SETTINGS
#########################################
#------------------------------------
# HARDWARE PERFORMANCE
#------------------------------------
# Choose the CPU / GPU value according to your hardware performance:
# PostProcessing quality:
# 1=Low, 2=Medium, 3=High
CPU=2
GPU=2

#-----------------------------------
# AUDIO SETTINGS (OPTIONAL)
#-----------------------------------

# AUDIO OUTPUT FOR SURROUND [default: "hdmi"]
#------------------------------------
# Select the audio output according to your hardware
# SPDIF: "iec958" or "spdif"
# HDMI:  "hdmi"
# If these values don't work, you have to select the right output for your hardware ($ aplay -L)
AO_SURROUND="hdmi"

# SURROUND CHANNELS FORMAT
#------------------------------------
# Select the channels format according to your hardware
# "7.1", "6.1", "5.1", "4.1", "3.1", "2.1" [default: "5.1"]
CHANNELS_FORMAT="5.1"

# CUSTOM AUDIO OUTPUT
#------------------------------------
# You can select custom audio output
# Bypass audio settings
# Exemples:
# AUDIO_CS="--ao=alsa:device=hdmi --audio-channels=6 --af=format=channels=5.1"
AUDIO_CS=""

#-----------------------------------
# VIDEO SETTINGS (OPTIONAL)
#-----------------------------------

# SHADERS PATH
#------------------------------------
# If you use the Shaders adapt the path accordingly
SHADER_PATH="/Path/To/Your/Folder/"
DEBAND_SHADER_PATH="${SHADER_PATH}deband.glsl"

# SHADERS
#------------------------------------
# Use Deband shader (true) or not (false) [default: false]
# Need a good GPU
# Don't use it. Not available at the moment in the latest MPV. Will be updated we it's available.
DEBAND_SHADER_UHD=false
DEBAND_SHADER_UHD_HIFPS=false
DEBAND_SHADER_FHD=false
DEBAND_SHADER_FHD_HIFPS=false
DEBAND_SHADER_HD=false
DEBAND_SHADER_HD_HIFPS=false
DEBAND_SHADER_SD=false
DEBAND_SHADER_SD_HIFPS=false

# INTERPOLATION
#------------------------------------
# Use Interpolation (true) or not (false) [default: false]
# Need a good GPU
SMOOTH_UHD=false
SMOOTH_UHD_HIFPS=false
SMOOTH_FHD=false
SMOOTH_FHD_HIFPS=false
SMOOTH_HD=false
SMOOTH_HD_HIFPS=false
SMOOTH_SD=false
SMOOTH_SD_HIFPS=false

# CUSTOM VIDEO OUTPUT AND VIDEO FILTERS
#------------------------------------
# You can select custom video output and/or video filters for each profiles
# Bypass everything except VapourSynth settings that can be used in complement
# Exemples:
# VO_HD="--vo=opengl-hq:scale=ewa_lanczossharp:scale-antiring=1.0"
# VF_HD="--vf=lavfi=\"gradfun=1.2:16\":o=\"threads=4,thread_type=slice\""
VO_UHD=""
VF_UHD=""

VO_UHD_HIFPS=""
VF_UHD_HIFPS=""

VO_FHD=""
VF_FHD=""

VO_FHD_HIFPS=""
VF_FHD_HIFPS=""

VO_HD=""
VF_HD=""

VO_HD_HIFPS=""
VF_HD_HIFPS=""

VO_SD=""
VF_SD=""

VO_SD_HIFPS=""
VF_SD_HIFPS=""

#------------------------------------
# VAPOUSYNTH SETTINGS (OPTIONAL)
#------------------------------------

# VAPOURSYNTH SCRIPT PATH
#------------------------------------
# If you use VapourSynth adapt the path accordingly
VS_PATH="/Path/To/Your/Folder/vapoursynth.py"

# VAPOURSYNTH
#------------------------------------
# Use VapourSynth (true) or not (false) [default: false]
# Need a good CPU
VAPOURSYNTH_UHD=false
VAPOURSYNTH_UHD_HIFPS=false
VAPOURSYNTH_FHD=false
VAPOURSYNTH_FHD_HIFPS=false
VAPOURSYNTH_HD=true
VAPOURSYNTH_HD_HIFPS=false
VAPOURSYNTH_SD=true
VAPOURSYNTH_SD_HIFPS=false
#########################################
# END USER SETTINGS
#########################################

############################################################
############################################################
# FROM HERE DON'T TOUCH ANYTHING
############################################################
############################################################

#########################################
# FUNCTION
#########################################
vo () {	
	if ${1}; then
		VO="--vo=opengl-hq:scale=ewa_lanczossharp:scale-antiring=1.0"
	fi
}

vf () {
	PP=""
	SS_PR=""
	SH=""
	SS_PO=""
	DB=""
	SS_SC=""

	if ${2}; then
		PP="pp=hb,"
	fi
	if ${3} && [ ${1} = "UP" ]; then
		SS_PR="scale=w=${6}*iw:h=${6}*ih,"
	fi
	if ${4}; then
		SH="unsharp=3:3:${7},"
	fi
	if ${3} && [ ${1} = "UP" ]; then
		SS_PO="scale=w=iw/${6}:h=ih/${6},"
	fi
	if ${5}; then
		DB="gradfun=1.2:16"
	fi
	if ${3} && [ ${1} = "UP" ]; then
		SS_SC=":sws-flags=0x400"
	fi

	if [ -n "${PP}" ] || [ -n "${SS_PR}" ] || [ -n "${SH}" ] || [ -n "${SS_PO}" ] || [ -n "${DB}" ] || [ -n "${SS_SC}" ]; then
		VF="--vf-add=lavfi=\"${PP}${SS_PR}${SH}${SS_PO}${DB}\"${SS_SC}:o=\"threads=${CORE},thread_type=slice\""
	fi
}

#########################################
# GET SOME INFOS
#########################################
# Get number of CPU
CORE=`grep -c ^processor /proc/cpuinfo`

# Get display resolution
DISP_RES=`xrandr | grep '\*' | cut -d' ' -f4`
#IFS='x' read -a AR <<< "${DISP_RES}"
DISP_RES_ARRAY=(${DISP_RES//x/ })
DISP_WIDTH="${DISP_RES_ARRAY[0]}"
DISP_HEIGHT="${DISP_RES_ARRAY[1]}"

# Get movie path and surround value
SURROUND=false
if [ ${#} = 2 ]; then
	if [ ${1} = "surround" ]; then
		SURROUND=true
		# Set channels according to user choice
		CHANNELS_FORMAT_ARRAY=(${CHANNELS_FORMAT//./ })
		CHANNELS=$((${CHANNELS_FORMAT_ARRAY[0]} + ${CHANNELS_FORMAT_ARRAY[1]}))
	fi
	MOVIE=${2}
else
	MOVIE=${1}
fi

# Get video infos
WIDTH=`mediainfo '--Inform=Video;%Width%' "${MOVIE}"`
HEIGHT=`mediainfo '--Inform=Video;%Height%' "${MOVIE}"`
FPS=`mediainfo '--Inform=Video;%FrameRate%' "${MOVIE}"`
FPS=${FPS%.*}

# Variables
VO="--vo=opengl-hq"
VF=""
AUDIO=""

VF_VS="--vf-add=vapoursynth=${VS_PATH}"

SSF=1.5
SSTR=1.2

HQ_SCALING=true
NO_HQ_SCALING=false

DEBLOCK=true
NO_DEBLOCK=false

SS=true
NO_SS=false

SHARPEN=true
NO_SHARPEN=false

DEBAND=true
NO_DEBAND=false

#########################################
# POSTPROCESSING
#########################################
if [ -n "${WIDTH}" ] && [ -n "${HEIGHT}" ] && [ -n "${FPS}" ]; then
	SCALE=false
	if [ ${WIDTH} -gt ${DISP_WIDTH} ] || [ ${HEIGHT} -gt ${DISP_HEIGHT} ]; then
		SCALE="DOWN"
	elif [ ${WIDTH} -lt ${DISP_WIDTH} ] && [ ${HEIGHT} -lt ${DISP_HEIGHT} ]; then
		SCALE="UP"
	fi

	# 4k - UHD - 2160p
	if [ ${WIDTH} -ge 1921 ] || [ ${HEIGHT} -ge 1081 ]; then
		if [ ${FPS} -le 30 ]; then
			if ! ${VAPOURSYNTH_UHD}; then
				if ${DEBAND_SHADER_UHD}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${NO_HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_UHD}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_UHD}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_UHD}" ]; then
				VO=${VO_UHD}
			fi
			if [ -n "${VF_UHD}" ]; then
				VF=${VF_UHD}
			fi		
		else
			if ! ${VAPOURSYNTH_UHD_HIFPS}; then
				if ${DEBAND_SHADER_UHD_HIFPS}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${NO_HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${NO_HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_UHD_HIFPS}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_UHD_HIFPS}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_UHD_HIFPS}" ]; then
				VO=${VO_UHD_HIFPS}
			fi
			if [ -n "${VF_UHD_HIFPS}" ]; then
				VF=${VF_UHD_HIFPS}
			fi
		fi
	# Full HD - 1080p
	elif [ ${WIDTH} = 1920 ] || [ ${HEIGHT} -ge 721 ]; then
		if [ ${FPS} -le 30 ]; then
			if ! ${VAPOURSYNTH_FHD}; then
				if ${DEBAND_SHADER_FHD}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi
			else
				VS=${VF_VS}	
			fi

			if ${DEBAND_SHADER_FHD}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_FHD}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_FHD}" ]; then
				VO=${VO_FHD}
			fi
			if [ -n "${VF_FHD}" ]; then
				VF=${VF_FHD}
			fi		
		else
			if ! ${VAPOURSYNTH_FHD_HIFPS}; then
				if ${DEBAND_SHADER_FHD_HIFPS}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${NO_HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_FHD_HIFPS}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_FHD_HIFPS}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_FHD_HIFPS}" ]; then
				VO=${VO_FHD_HIFPS}
			fi
			if [ -n "${VF_FHD_HIFPS}" ]; then
				VF=${VF_FHD_HIFPS}
			fi
		fi
	# 720p
	elif [ ${WIDTH} = 1280 ] || [ ${HEIGHT} = 720 ]; then
		if [ ${FPS} -le 30 ]; then
	    	if ! ${VAPOURSYNTH_HD}; then
	    		if ${DEBAND_SHADER_HD}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_HD}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_HD}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_HD}" ]; then
				VO=${VO_HD}
			fi
			if [ -n "${VF_HD}" ]; then
				VF=${VF_HD}
			fi		
		else
			if ! ${VAPOURSYNTH_HD_HIFPS}; then
				if ${DEBAND_SHADER_HD_HIFPS}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_HD_HIFPS}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_HD_HIFPS}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_HD_HIFPS}" ]; then
				VO=${VO_HD_HIFPS}
			fi
			if [ -n "${VF_HD_HIFPS}" ]; then
				VF=${VF_HD_HIFPS}
			fi
		fi
	# 480p
	else
		if [ ${FPS} -le 30 ]; then
			if ! ${VAPOURSYNTH_SD}; then
				if ${DEBAND_SHADER_SD}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_SD}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_SD}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_SD}" ]; then
				VO=${VO_SD}
			fi
			if [ -n "${VF_SD}" ]; then
				VF=${VF_SD}
			fi		
		else
			if ! ${VAPOURSYNTH_SD_HIFPS}; then
				if ${DEBAND_SHADER_SD}; then
					DEBAND=${NO_DEBAND}
				fi

				if [ ${CPU} = 3 ]; then
					vf ${SCALE} ${DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 2 ]; then
					vf ${SCALE} ${DEBLOCK} ${SS} ${SHARPEN} ${DEBAND} ${SSF} ${SSTR}
				elif [ ${CPU} = 1 ]; then
					vf ${SCALE} ${NO_DEBLOCK} ${NO_SS} ${NO_SHARPEN} ${NO_DEBAND} ${SSF} ${SSTR}
				fi	
				if [ ${GPU} = 3 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 2 ]; then
					vo ${HQ_SCALING}
				elif [ ${GPU} = 1 ]; then
					vo ${NO_HQ_SCALING}
				fi	
			else
				VS=${VF_VS}
			fi

			if ${DEBAND_SHADER_SD_HIFPS}; then
				VO="${VO}:post-shaders=${DEBAND_SHADER_PATH}"
			fi

			if ${SMOOTH_SD_HIFPS}; then
				VO="${VO}:interpolation"
			fi

			if [ -n "${VO_SD_HIFPS}" ]; then
				VO=${VO_SD_HIFPS}
			fi
			if [ -n "${VF_SD_HIFPS}" ]; then
				VF=${VF_SD_HIFPS}
			fi
		fi
	fi
fi

# Surround audio output
if ${SURROUND} && ! [ -n "${AUDIO_CS}" ]; then
	AUDIO="--ao=alsa:device=${AO_SURROUND} --audio-channels=${CHANNELS} --af=format=channels=${CHANNELS_FORMAT}"
elif [ -n "${AUDIO_CS}" ]; then
	AUDIO=${AUDIO_CS}
fi

# START MPV
mpv ${VO} ${VF} ${VS} ${AUDIO} "${MOVIE}"

