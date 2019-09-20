#!/bin/bash

function enter_to_continue() {
    read -p "Press [enter] to continue."
}

function clear_and_exit() {
    rm -f temp.mfd
    exit $1
}

clear
echo "Welcome to NFC card simulation script!"
echo "    _   ______________     ________               "
echo "   / | / / ____/ ____/    / ____/ /___  ____  ___ " 
echo "  /  |/ / /_  / /  ______/ /   / / __ \\/ __ \\/ _ \\"
echo " / /|  / __/ / /__/_____/ /___/ / /_/ / / / /  __/"
echo "/_/ |_/_/    \____/     \____/_/\\____/_/ /_/\\___/ "
echo "Please connect your PN532 board to this computer and prepare an empty UID card."
enter_to_continue

# Scan NFC device
nfc-scan-device 2>&1 | grep error
if [ $? == 0 ]
then
    echo -e "\033[1;31mError:\033[0m cannot connect to PN532 board."
    clear_and_exit -1
fi

# Read and crack NFC card
clear
echo "== Step 1: Put your original NFC card on the PN532 board."
enter_to_continue
mfoc -O temp.mfd
if [ $? -ne 0 ]
then
    echo -e "\033[1;31mError:\033[0m cannot crack the card."
    clear_and_exit -1
fi

# Write empty card
clear
echo "== Step 2: Remove the original card and put your empty UID card on the PN532 board."
enter_to_continue
CARD_UID=`hexdump -n 4 -e  '4 1 "%02x"' temp.mfd`
nfc-mfsetuid $CARD_UID
if [ $? -ne 0 ]
then
    echo -e "\033[1;31mError:\033[0m cannot write UID of the empty card."
    clear_and_exit -1
fi

# Write real card
clear
echo "== Step 3: Put the target card on the PN532 board."
echo "   * Clone to the empty card, just put the empty card on the board."
echo "   * Clone to your phone or band, please open a new keycard, enable it, and put your phone/band on the board."
enter_to_continue
nfc-mfclassic w a temp.mfd
if [ $? -ne 0 ]
then
    echo -e "\033[1;31mError:\033[0m cannot write the target card."
    clear_and_exit -1
fi

clear_and_exit 0
