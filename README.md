# L01 – Bunk Calculator

**Student:** PATEL YAGNA | **Roll:** G22 | **Division:** G | **Enrollment:** 24004501210297

## Problem
Build an attendance tracker that records daily attendance per subject and tells you exactly how many lectures you can still miss (or must attend) to stay above 75%.

## Who will use it
College students and professors who want to track daily subject-wise attendance and prevent debarment by maintaining attendance above the mandatory 75% threshold.

## Folder structure
- `main.sh` – Interactive menu script (supports CLI flags: `--help`, `--backup`, `--cron`)
- `lib/functions.sh` – Modular function library containing features 1–5, backup, log, and cron routines
- `data/` – Contains `attendance.csv` (historical and active attendance records)
- `reports/` – Output directory for dated monthly reports and automated cron run outputs
- `backups/` – Automated `.tar.gz` archive snapshots of the data directory
- `logs/` – Persistent operational audit trail (`activity.log` and `cron.log`)
- `reminders.txt` – Target file for daily 6 PM cron notifications

## Features
1. **Add today's attendance for a subject:** Prompts for date, subject, and status (P/A) with input validation, appending to `attendance.csv`.
2. **Show subject-wise attendance % using awk:** Computes total sessions, present count, absent count, and percentage per subject.
3. **List subjects below 75% (danger list):** Filters subjects failing the 75% mark and calculates the percentage deficit.
4. **Calculate how many more lectures you can bunk / must attend:** Uses mathematical formulas ($\lfloor (4P - 3T)/3 \rfloor$ for safe bunks and $(3T - 4P)$ for recovery) to recommend exact lecture counts.
5. **Save a dated monthly report to reports/:** Exports formatted text summary report (`reports/report_YYYY-MM-DD.txt`).
6. **View raw data:** Displays numbered entries of `data/attendance.csv`.
7. **Backup data:** Generates timestamped `.tar.gz` archive in `backups/`.
8. **View activity log:** Displays recent timestamped activities from `logs/activity.log`.

## How to run
```bash
# Navigate to the project directory
cd bunkcalc

# Interactive menu mode:
./main.sh

# Display command line help:
./main.sh --help

# Create immediate data backup:
./main.sh --backup

# Trigger scheduled cron task:
./main.sh --cron
```

## Crontab task
Every day at 6 PM, append a 'mark your attendance' reminder and the subjects below 75% to `reminders.txt`:
```crontab
0 18 * * * /bin/bash $HOME/linux_project/bunkcalc/main.sh --cron >> $HOME/linux_project/bunkcalc/logs/cron.log 2>&1
```

### Explanation of Crontab Fields:
- `0`  : Minute 0 (on the hour)
- `18` : Hour 18 (6:00 PM in 24-hour time)
- `*`  : Day of month (every day)
- `*`  : Month (every month)
- `*`  : Day of week (every day of the week)

## Commands used
`awk`, `sort`, `grep`, `date`, `printf`, `tar`, `wc`, `du`, `tail`, `cat`

## What I learned
1. Mastered stream processing and associative arrays in `awk` to aggregate CSV records and calculate conditional percentages.
2. Built robust interactive shell scripts utilizing modular function libraries (`source lib/functions.sh`), defensive input validation, and loop/case structures.
3. Configured cron scheduling (`crontab`) for automated maintenance, log redirection, and system reporting.
4. Implemented automated data preservation using `tar -czf` backups and created persistent audit logs with timestamps.
5. Gained practical experience in Linux CLI automation and terminal-driven utility development.

## Project Guide
This project was completed under the guidance of **Dr. Anjum Y. Mansuri**, Assistant Professor, Computer Applications, LJ Institute of Computer Applications, LJ University, Ahmedabad.  
GitHub: [@anjum-mansuri](https://github.com/anjum-mansuri)

OS Linux Lab 260120510 | Project ID: L01
