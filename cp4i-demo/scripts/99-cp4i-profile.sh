#!/bin/sh
echo "Sourcing Env Variables"
#
# OCP_TYPE
#
OCP_TYPE=ODF
#OCP_TYPE=ROKS
export OCP_TYPE
#
# CP4I_VER 
#
#CP4I_VER=2022.2
#CP4I_VER=2022.4
CP4I_VER=2023.2
export CP4I_VER
#
#
#
CP4I_TRACING=NO
export CP4I_TRACING
echo "Env Variables have been set"
echo "OCP_TYPE:" $OCP_TYPE
echo "CP4I_VER:" $CP4I_VER
echo "CP4I_TRACING:" $CP4I_TRACING