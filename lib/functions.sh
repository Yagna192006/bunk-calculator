#!/bin/bash
# lib/functions.sh – all functions for Bunk Calculator
# Student: PATEL YAGNA | Roll: G22 | Div: G | Enrollment: 24004501210297

DATA="data/attendance.csv"
LOG="logs/activity.log"
REMINDERS="reminders.txt"

# write one line to the activity log
log() {
    mkdir -p logs
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOG"
}

# check the data file exists before using it
check_data() {
    if [ ! -f "$DATA" ]; then
        echo "Error: Data file not found: $DATA"
        log "check_data: error data file missing ($DATA)"
        return 1
    fi
}

show_help() {
    echo "=================================================="
    echo "          L01 - BUNK CALCULATOR HELP"
    echo "=================================================="
    echo "Usage: ./main.sh            -> Open interactive menu"
    echo "       ./main.sh --help     -> Show this help message"
    echo "       ./main.sh --backup   -> Create tar.gz backup of data/ now"
    echo "       ./main.sh --cron     -> Run scheduled daily reminder (crontab task)"
    echo "=================================================="
}

view_data() {
    check_data || return 1
    echo "=================================================="
    echo "             CURRENT ATTENDANCE DATA"
    echo "=================================================="
    cat -n "$DATA"
    echo "--------------------------------------------------"
    total_records=$(($(wc -l < "$DATA") - 1))
    echo "Total attendance records: $total_records"
    log "view_data: displayed $total_records records"
}

do_backup() {
    mkdir -p backups
    f="backups/data_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$f" data/
    echo "Backup successfully created: $f"
    if [ -f "$f" ]; then
        echo "Backup size: $(du -h "$f" 2>/dev/null | cut -f1 || ls -lh "$f" | awk '{print $5}')"
    fi
    log "backup: created $f"
}

view_log() {
    echo "=================================================="
    echo "            RECENT ACTIVITY LOG (LAST 15)"
    echo "=================================================="
    if [ -f "$LOG" ]; then
        tail -n 15 "$LOG"
    else
        echo "No activity recorded yet."
    fi
    echo "=================================================="
}

# ------------------------------------------------------------
# FEATURE 1: Add today's attendance for a subject
# ------------------------------------------------------------
feature_1() {
    echo "=================================================="
    echo "   FEATURE 1: Add Attendance for a Subject"
    echo "=================================================="
    check_data || return 1

    local default_date
    default_date=$(date '+%Y-%m-%d')
    read -p "Enter date (YYYY-MM-DD) [Default: $default_date]: " in_date
    in_date="${in_date:-$default_date}"
    if [[ ! "$in_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Error: Invalid date format. Must be YYYY-MM-DD."
        return 1
    fi

    read -p "Enter subject (e.g. Linux, ML, DBMS, OS, CN): " in_sub
    in_sub=$(echo "$in_sub" | tr -d ' \t\r\n')
    if [ -z "$in_sub" ]; then
        echo "Error: Subject cannot be empty."
        return 1
    fi

    read -p "Enter status (P for Present / A for Absent): " in_status
    in_status=$(echo "$in_status" | tr '[:lower:]' '[:upper:]' | tr -d ' \t\r\n')
    if [ "$in_status" != "P" ] && [ "$in_status" != "A" ]; then
        echo "Error: Status must be either 'P' or 'A'."
        return 1
    fi

    echo "$in_date,$in_sub,$in_status" >> "$DATA"
    echo "Success: Recorded [$in_date | $in_sub | $in_status] in $DATA"
    log "feature_1: added record $in_date,$in_sub,$in_status"
}

# ------------------------------------------------------------
# FEATURE 2: Show subject-wise attendance % using awk
# ------------------------------------------------------------
feature_2() {
    echo "=================================================="
    echo "   FEATURE 2: Subject-Wise Attendance %"
    echo "=================================================="
    check_data || return 1

    printf "\n%-15s %-8s %-8s %-8s %-14s %-12s\n" "SUBJECT" "TOTAL" "PRESENT" "ABSENT" "ATTENDANCE %" "STATUS"
    printf "%-15s %-8s %-8s %-8s %-14s %-12s\n" "---------------" "-------" "-------" "-------" "--------------" "------------"
    awk -F',' '
    NR > 1 {
        sub(/^[ \t]+|[ \t\r]+$/, "", $2)
        sub(/^[ \t]+|[ \t\r]+$/, "", $3)
        subj = $2
        st = $3
        total[subj]++
        if (st == "P") pres[subj]++
        else if (st == "A") abs[subj]++
    }
    END {
        for (s in total) {
            p = (total[s] > 0) ? (pres[s] * 100.0 / total[s]) : 0
            tag = (p >= 75.0) ? "SAFE (>=75%)" : "DANGER (<75%)"
            printf "%-15s %-8d %-8d %-8d %-13.2f%% %-12s\n", s, total[s], pres[s], abs[s], p, tag
        }
    }' "$DATA" | sort -k1,1
    echo

    log "feature_2: displayed subject-wise attendance percentage"
}

# ------------------------------------------------------------
# FEATURE 3: List subjects below 75% (danger list)
# ------------------------------------------------------------
feature_3() {
    echo "=================================================="
    echo "   FEATURE 3: Danger List (Below 75% Attendance)"
    echo "=================================================="
    check_data || return 1

    local danger_rows
    danger_rows=$(awk -F',' '
    NR > 1 {
        sub(/^[ \t]+|[ \t\r]+$/, "", $2)
        sub(/^[ \t]+|[ \t\r]+$/, "", $3)
        subj = $2
        st = $3
        total[subj]++
        if (st == "P") pres[subj]++
        else if (st == "A") abs[subj]++
    }
    END {
        for (s in total) {
            p = (total[s] > 0) ? (pres[s] * 100.0 / total[s]) : 0
            if (p < 75.0) {
                deficit = 75.0 - p
                printf "%-15s %-8d %-8d %-8d %-13.2f%% -%-11.2f%%\n", s, total[s], pres[s], abs[s], p, deficit
            }
        }
    }' "$DATA" | sort -k1,1)

    printf "\n%-15s %-8s %-8s %-8s %-14s %-12s\n" "SUBJECT" "TOTAL" "PRESENT" "ABSENT" "ATTENDANCE %" "DEFICIT %"
    printf "%-15s %-8s %-8s %-8s %-14s %-12s\n" "---------------" "-------" "-------" "-------" "--------------" "------------"
    if [ -n "$danger_rows" ]; then
        echo "$danger_rows"
        local count
        count=$(echo "$danger_rows" | grep -c .)
        echo
        echo "Warning: $count subject(s) are below the mandatory 75% threshold!"
    else
        echo "Excellent! All subjects have 75% or higher attendance."
    fi
    echo

    log "feature_3: checked danger list"
}

# ------------------------------------------------------------
# FEATURE 4: Calculate bunk capacity / required attendance
# ------------------------------------------------------------
feature_4() {
    echo "=================================================="
    echo "   FEATURE 4: Bunk Calculator & Attendance Planner"
    echo "=================================================="
    check_data || return 1

    echo "Calculating for all subjects based on 75% minimum threshold..."
    printf "\n%-12s %-6s %-8s %-10s %-10s %-32s\n" "SUBJECT" "TOTAL" "PRESENT" "ATTEND %" "STATUS" "ACTION REQUIRED"
    printf "%-12s %-6s %-8s %-10s %-10s %-32s\n" "------------" "------" "--------" "----------" "----------" "--------------------------------"
    awk -F',' '
    NR > 1 {
        sub(/^[ \t]+|[ \t\r]+$/, "", $2)
        sub(/^[ \t]+|[ \t\r]+$/, "", $3)
        subj = $2
        st = $3
        total[subj]++
        if (st == "P") pres[subj]++
        else if (st == "A") abs[subj]++
    }
    END {
        for (s in total) {
            T = total[s]
            P = pres[s]
            pct = (T > 0) ? (P * 100.0 / T) : 0
            if (pct >= 75.0) {
                # Max bunk formula: (4*P - 3*T) / 3
                bunks = int((4 * P - 3 * T) / 3)
                if (bunks < 0) bunks = 0
                tag = "SAFE"
                if (bunks > 0) {
                    msg = sprintf("Can bunk %d lecture(s) safely", bunks)
                } else {
                    msg = "At 75%! Cannot bunk next lecture"
                }
            } else {
                # Must attend formula: 3*T - 4*P
                need = (3 * T) - (4 * P)
                if (need < 1) need = 1
                tag = "DANGER"
                msg = sprintf("Must attend next %d lecture(s)", need)
            }
            printf "%-12s %-6d %-8d %-9.2f%% %-10s %-32s\n", s, T, P, pct, tag, msg
        }
    }' "$DATA" | sort -k1,1
    echo

    log "feature_4: calculated bunk allowance and attendance requirement"
}

# ------------------------------------------------------------
# FEATURE 5: Save a dated monthly report to reports/
# ------------------------------------------------------------
feature_5() {
    echo "=================================================="
    echo "   FEATURE 5: Generate Dated Attendance Report"
    echo "=================================================="
    check_data || return 1

    mkdir -p reports
    local report_date
    report_date=$(date +%Y-%m-%d)
    local out="reports/report_${report_date}.txt"

    {
        echo "================================================================"
        echo "             L01 BUNK CALCULATOR - MONTHLY REPORT"
        echo "================================================================"
        echo "Generated on : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Student      : PATEL YAGNA | Roll: G22 | Div: G"
        echo "Enrollment   : 24004501210297"
        echo "Data source  : $DATA"
        echo "----------------------------------------------------------------"
        echo "1. OVERALL STATISTICS"
        awk -F',' '
        NR > 1 {
            sub(/^[ \t]+|[ \t\r]+$/, "", $3)
            tot++
            if ($3 == "P") pres++
            else if ($3 == "A") abs++
        }
        END {
            pct = (tot > 0) ? (pres * 100.0 / tot) : 0
            printf "   Total Lectures Conducted : %d\n", tot
            printf "   Total Attended (Present) : %d\n", pres
            printf "   Total Missed (Absent)    : %d\n", abs
            printf "   Aggregate Attendance Rate: %.2f%%\n", pct
        }' "$DATA"

        echo "----------------------------------------------------------------"
        echo "2. SUBJECT-WISE BREAKDOWN"
        awk -F',' '
        NR > 1 {
            sub(/^[ \t]+|[ \t\r]+$/, "", $2)
            sub(/^[ \t]+|[ \t\r]+$/, "", $3)
            subj = $2
            st = $3
            total[subj]++
            if (st == "P") pres[subj]++
            else if (st == "A") abs[subj]++
        }
        END {
            printf "   %-14s %-8s %-8s %-8s %-12s %-10s\n", "SUBJECT", "TOTAL", "PRESENT", "ABSENT", "PERCENT", "STATUS"
            printf "   %-14s %-8s %-8s %-8s %-12s %-10s\n", "--------------", "-------", "-------", "-------", "------------", "----------"
            for (s in total) {
                p = (total[s] > 0) ? (pres[s] * 100.0 / total[s]) : 0
                tag = (p >= 75.0) ? "SAFE" : "LOW (<75%)"
                printf "   %-14s %-8d %-8d %-8d %-11.2f%% %-10s\n", s, total[s], pres[s], abs[s], p, tag
            }
        }' "$DATA"

        echo "----------------------------------------------------------------"
        echo "3. BUNK & RECOVERY PLAN"
        awk -F',' '
        NR > 1 {
            sub(/^[ \t]+|[ \t\r]+$/, "", $2)
            sub(/^[ \t]+|[ \t\r]+$/, "", $3)
            subj = $2
            st = $3
            total[subj]++
            if (st == "P") pres[subj]++
        }
        END {
            printf "   %-14s %-12s %-30s\n", "SUBJECT", "STATUS", "RECOMMENDATION"
            printf "   %-14s %-12s %-30s\n", "--------------", "------------", "------------------------------"
            for (s in total) {
                T = total[s]
                P = pres[s]
                pct = (T > 0) ? (P * 100.0 / T) : 0
                if (pct >= 75.0) {
                    bunks = int((4 * P - 3 * T) / 3)
                    if (bunks < 0) bunks = 0
                    msg = (bunks > 0) ? sprintf("Can bunk %d lecture(s)", bunks) : "Cannot miss next lecture"
                    printf "   %-14s %-12s %-30s\n", s, "SAFE", msg
                } else {
                    need = (3 * T) - (4 * P)
                    if (need < 1) need = 1
                    msg = sprintf("Must attend %d lecture(s) in a row", need)
                    printf "   %-14s %-12s %-30s\n", s, "DANGER", msg
                }
            }
        }' "$DATA"
        echo "================================================================"
        echo "End of Report."
    } > "$out"

    echo "Report generated and saved to: $out"
    echo "Preview of report:"
    cat "$out"
    log "feature_5: saved monthly report to $out"
}

# ------------------------------------------------------------
# CRON TASK: Daily 6 PM reminder and danger list
# ------------------------------------------------------------
cron_task() {
    mkdir -p reports logs
    local now
    now=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo "================================================================"
        echo "[$now] DAILY ATTENDANCE & DANGER LIST REMINDER"
        echo "================================================================"
        echo "Reminder: Please remember to mark today's attendance in Bunk Calculator!"
        echo ""
        echo "Subjects currently below 75% attendance threshold:"
        awk -F',' '
        NR > 1 {
            sub(/^[ \t]+|[ \t\r]+$/, "", $2)
            sub(/^[ \t]+|[ \t\r]+$/, "", $3)
            subj = $2
            st = $3
            total[subj]++
            if (st == "P") pres[subj]++
            else if (st == "A") abs[subj]++
        }
        END {
            found = 0
            for (s in total) {
                p = (total[s] > 0) ? (pres[s] * 100.0 / total[s]) : 0
                if (p < 75.0) {
                    found++
                    need = (3 * total[s]) - (4 * pres[s])
                    if (need < 1) need = 1
                    printf "  * %s: %.2f%% attendance (Must attend next %d lecture(s) consecutively!)\n", s, p, need
                }
            }
            if (found == 0) {
                print "  All subjects are currently above 75%. Keep it up!"
            }
        }' "$DATA"
        echo "================================================================"
        echo ""
    } | tee -a "$REMINDERS" >> reports/cron_output.txt

    log "cron_task: executed scheduled reminder task"
    echo "Cron reminder appended to $REMINDERS and reports/cron_output.txt"
}
