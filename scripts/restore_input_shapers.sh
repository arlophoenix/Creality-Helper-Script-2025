#!/bin/sh

set -e

function restore_input_shapers_message(){
  top_line
  title 'Restore Input Shapers' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}The K1C 2025 firmware ships input-shaper calibration limited ${white}│"
  echo -e " │ ${cyan}to a single model (ei) and copies the Y-axis result onto X. ${white}│"
  echo -e " │ ${cyan}This restores the full Klipper shaper model set and          ${white}│"
  echo -e " │ ${cyan}independent per-axis calibration.                            ${white}│"
  hr
  bottom_line
}

function install_restore_input_shapers(){
  restore_input_shapers_message
  local yn
  while true; do
    install_msg "Restore Input Shapers" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        # 1. Restore the full shaper model set.
        # Creality's compiled shaper_defs.pyc trims INPUT_SHAPERS down to 'ei', so
        # SHAPER_CALIBRATE only ever fits ei. Dropping the stock shaper_defs.py beside it
        # makes Python load the source (a legacy .pyc next to source is ignored when the
        # .py is present), restoring zv/mzv/ei/2hump_ei/3hump_ei. shaper_calibrate.pyc
        # already knows every model; only the definitions list was stripped.
        echo -e "Info: Restoring full input-shaper model set..."
        cp -f "$RESTORE_SHAPERS_URL" "$SHAPER_DEFS_FILE"
        chmod 644 "$SHAPER_DEFS_FILE"
        chown creality:creality "$SHAPER_DEFS_FILE" 2>/dev/null || true
        rm -f "$KLIPPER_EXTRAS_FOLDER"/__pycache__/shaper_defs.*pyc 2>/dev/null || true
        # 2. Calibrate X and Y independently (Creality copies Y->X by default via the
        # resonance_tester 'axis_x_use_y' option, which defaults to true).
        if grep -q "^[[:space:]]*axis_x_use_y" "$PRINTER_CFG" ; then
          echo -e "Info: Independent X/Y calibration is already enabled in printer.cfg file..."
        elif grep -q "^\[resonance_tester\]" "$PRINTER_CFG" ; then
          echo -e "Info: Enabling independent X/Y calibration in printer.cfg file..."
          awk '{print} /^\[resonance_tester\]/{print "axis_x_use_y: false"}' "$PRINTER_CFG" > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        else
          echo -e "${red}Warning: no [resonance_tester] section in printer.cfg; skipping axis_x_use_y.${white}"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Restore Input Shapers has been installed successfully!"
        echo -e " ${cyan}Run ${white}SHAPER_CALIBRATE${cyan} from the console, then ${white}SAVE_CONFIG${cyan} to apply.${white}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_restore_input_shapers(){
  restore_input_shapers_message
  local yn
  while true; do
    remove_msg "Restore Input Shapers" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing restored shaper definitions (Creality's shaper_defs.pyc takes over again)..."
        rm -f "$SHAPER_DEFS_FILE"
        rm -f "$KLIPPER_EXTRAS_FOLDER"/__pycache__/shaper_defs.*pyc 2>/dev/null || true
        if grep -q "^[[:space:]]*axis_x_use_y" "$PRINTER_CFG" ; then
          echo -e "Info: Disabling independent X/Y calibration in printer.cfg file..."
          grep -v "^[[:space:]]*axis_x_use_y" "$PRINTER_CFG" > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        else
          echo -e "Info: Independent X/Y calibration is already disabled in printer.cfg file..."
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Restore Input Shapers has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
