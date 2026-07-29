#!/bin/bash

###############################################################################
# Engine
###############################################################################

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/cli.sh"
source "$SCRIPT_DIR/lib/init.sh"
source "$SCRIPT_DIR/lib/findings.sh"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/notify.sh"

###############################################################################
# Providers
###############################################################################

source "$SCRIPT_DIR/lib/providers/hp_raid.sh"
source "$SCRIPT_DIR/lib/providers/smart.sh"
