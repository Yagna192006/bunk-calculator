#!/bin/bash
# main.sh – L01 Bunk Calculator
# Student: PATEL YAGNA | Roll: G22 | Div: G | Enrollment: 24004501210297
# Menu-driven shell script (while loop + case)

cd "$(dirname "$0")" || exit 1
source lib/functions.sh

case "$1" in
    --help)   show_help; exit 0 ;;
    --backup) do_backup; exit 0 ;;
    --cron)   cron_task; exit 0 ;;
esac

while true; do
    echo
    echo '=================================================='
    echo '              BUNK CALCULATOR MENU'
    echo '=================================================='
    echo "1) Add today's attendance for a subject"
    echo "2) Show subject-wise attendance % using awk"
    echo "3) List subjects below 75% (danger list)"
    echo "4) Calculate bunk capacity & lectures needed"
    echo "5) Save a dated monthly report to reports/"
    echo "6) View raw attendance data"
    echo "7) Backup data (tar.gz)"
    echo "8) View activity log"
    echo "0) Exit"
    echo '=================================================='
    read -p "Choose an option [0-8]: " ch
    case "$ch" in
        1) feature_1 ;;
        2) feature_2 ;;
        3) feature_3 ;;
        4) feature_4 ;;
        5) feature_5 ;;
        6) view_data ;;
        7) do_backup ;;
        8) view_log ;;
        0) echo "Thank you for using Bunk Calculator. Goodbye!"; break ;;
        *) echo "Invalid choice: '$ch'. Please choose a number between 0 and 8." ;;
    esac
done
