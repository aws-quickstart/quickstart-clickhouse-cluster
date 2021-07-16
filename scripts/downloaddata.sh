#!/usr/bin/env bash
rm -f list_urls.txt

for s in `seq ontimefrom ontimeto`
do
for m in `seq 1 12`
do
echo "https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_${s}_${m}.zip" >> list_urls.txt
done
done

mywget()
{
    wget -t 3 -c -S "$1" --no-check-certificate
}

export -f mywget

# run wget in parallel using 5 thread/connection
xargs -P 5 -n 1 -I {} bash -c "mywget '{}'" < list_urls.txt