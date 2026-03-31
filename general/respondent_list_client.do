*===================================================*
* Agent - Client Survey (Baseline) -- Match
* Last modified: 05 Feb 2026
* Last modified by: Naufal
* Stata version: 16
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
gl user = c(username)

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

*Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

* Set the path
    gl do            "$path/dofiles/client_baseline"
    gl dta           "$path/dtafiles"
    gl log           "$path/logfiles"
    gl output        "$path/output"
    gl raw           "$path/10 Respondent List/01_daftar_penerima_baseline_client"

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_pertama_final.xls", sheet("Sheet1") firstrow clear
    tempfile client_pertama
    save `client_pertama'

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_kedua_final.xls", sheet("Sheet1") firstrow clear
    tempfile client_kedua
    save `client_kedua'

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_ketiga_final_part1.xlsx", sheet("Sheet1") firstrow clear
    tempfile client_ketiga1
    save `client_ketiga1'

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_ketiga_final_part2.xlsx", sheet("Sheet1") firstrow clear
    tempfile client_ketiga2
    save `client_ketiga2'

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_keempat_final.xls", sheet("Sheet1") firstrow clear
    tempfile client_keempat
    save `client_keempat'

import excel "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_kelima_final.xlsx", sheet("Sheet1") firstrow clear
    tempfile client_kelima
    save `client_kelima'

    *Generating number of blast for each client

    use `client_pertama', clear
    gen b1 = 1

    merge 1:1 kode_unik_survei_nasabah using `client_kedua'
    gen b2 = (_merge != 1)
    drop _merge

    merge 1:1 kode_unik_survei_nasabah using `client_ketiga1'
    gen b3 = (_merge != 1)
    drop _merge

    merge 1:1 kode_unik_survei_nasabah using `client_ketiga2'
    gen b3_2 = (_merge != 1)
    drop _merge

    merge 1:1 kode_unik_survei_nasabah using `client_keempat'
    gen b4 = (_merge != 1)
    drop _merge

    merge 1:1 kode_unik_survei_nasabah using `client_kelima'
    gen b5 = (_merge != 1)
    drop _merge

    egen total_reminder = rowtotal(b1 b2 b3 b3_2 b4 b5)

save "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/daftar_penerima_baseline_client.dta", replace

