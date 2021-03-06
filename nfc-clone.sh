#!/bin/bash
trap 'rm -f "$TMP_FILE" "$EMPTY_FILE"' EXIT

function enter_to_continue() {
    read -p "Press [enter] to continue..."
}

check_return_value() {
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31mError:\033[0m $1."
        exit -1
    fi
}

prompt_yes_or_no() {
    while true; do
        read -r -p "Do you want to save the card dump file? [Y/N]" INPUT
        case $INPUT in
        [yY][eE][sS] | [yY]) return 0 ;;
        [nN][oO] | [nN]) return 1 ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
}

clear
echo "    _   ______________     ________               "
echo "   / | / / ____/ ____/    / ____/ /___  ____  ___ "
echo "  /  |/ / /_  / /  ______/ /   / / __ \\/ __ \\/ _ \\"
echo " / /|  / __/ / /__/_____/ /___/ / /_/ / / / /  __/"
echo "/_/ |_/_/    \\____/     \\____/_/\\____/_/ /_/\\___/ "
echo ""
echo "Please connect your PN532 board to this computer and prepare an empty UID card."
enter_to_continue

# Scan NFC device
! nfc-scan-device 2>&1 | grep error
check_return_value "cannot connect to PN532 board"

# Read and crack NFC card
clear
echo "== Step 1: Put your original NFC card on the PN532 board."
enter_to_continue

TMP_FILE=$(mktemp tmp.XXXXXXXXXXXXXXXX)
check_return_value "cannot make temporary file"

mfoc -O $TMP_FILE
check_return_value "cannot crack the card"

# Save the dump file
prompt_yes_or_no
if [[ $? == 0 ]]; then
    SAVE_FILE=$(date "+%Y-%m-%d_%H-%M-%S")".mfd"
    cp $TMP_FILE $SAVE_FILE
fi

# Write empty card
clear
echo "== Step 2: Remove the original card and put your empty UID card on the PN532 board."
enter_to_continue

EMPTY_FILE=$(mktemp tmp.XXXXXXXXXXXXXXXX)
head -c 16 $TMP_FILE >$EMPTY_FILE
cat .empty.mfd >>$EMPTY_FILE
nfc-mfclassic W a $EMPTY_FILE
check_return_value "cannot write UID of the empty card"

# Write real card
clear
echo "== Step 3: Put the target card on the PN532 board."
echo "   * Clone to the empty card, just put the empty card on the board."
echo "   * Clone to your phone or band, please open a new keycard, enable it, and put your phone/band on the board."
enter_to_continue

nfc-mfclassic w a $TMP_FILE
check_return_value "cannot write the target card"

exit 0
