@echo off

wt ^
new-tab --title "load-dbteam" --tabColor "#00CC66" ssh load-dbteam ; ^
new-tab --title "k6-1" --tabColor "#B3E5FC" ssh k6-1 ; ^
new-tab --title "k6-2" --tabColor "#81D4FA" ssh k6-2 ; ^
new-tab --title "k6-3" --tabColor "#4FC3F7" ssh k6-3 ; ^
new-tab --title "k6-4" --tabColor "#29B6F6" ssh k6-4 ; ^
new-tab --title "k6-5" --tabColor "#0277BD" ssh k6-5
`