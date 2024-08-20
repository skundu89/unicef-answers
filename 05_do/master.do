cap restore
clear all

global root "C:\Users\wb525851\OneDrive - WBG\Documents\GitHub" //change to your local github location
global repo "$root/unicef-answers" //ensure this repository is cloned
global raw_data "$repo/01_rawdata"
global admin_data "$repo/02_admindata"
global working_folder "$repo/03_working"
global output "$repo/04_output"
global do "$repo/05_do"

do "$do/task1.do"
do "$do/task2.do"