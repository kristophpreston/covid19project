##This script has a JQ Dependency! Make sure you have it installed!
##The script tends to have issues around the 60~ day pull, if it gives you issues on a 60 day pull, go to 90 days and it shouldn't be throwing "Invalid Numeric Literal" errors.

#!/bin/bash

## Start day value blank
dayValue=""

#### INTERACTIVE MENU START  ####

echo "How many days back should we output? default (and minimum) is 60. Leave blank to pull all data available"
read dayValue
echo "Thank you, processing the data now. Please be patient"

#### INTERACTIVE MENU END  ####


## Declare a string array with municipality names.
declare -a StringArray=("ADJUNTAS" "AGUADA" "AGUADILLA" "AGUAS_BUENAS" "AIBONITO" "ANASCO" "ARECIBO" "ARROYO" "BARCELONETA" "BARRANQUITAS" "BAYAMON" "CABO_ROJO" "CAGUAS" "CAMUY" "CANOVANAS" "CAROLINA" "CATANO" "CAYEY" "CEIBA" "CIALES" "CIDRA" "COAMO" "COMERIO" "COROZAL" "CULEBRA" "DORADO" "FAJARDO" "FLORIDA" "GUANICA" "GUAYAMA" "GUAYANILLA" "GUAYNABO" "GURABO" "HATILLO" "HORMIGUEROS" "HUMACAO" "ISABELA" "JAYUYA" "JUANA_DIAZ" "JUNCOS" "LAJAS" "LARES" "LAS_MARIAS" "LAS_PIEDRAS" "LOIZA" "LUQUILLO" "MANATI" "MARICAO" "MAUNABO" "MAYAGUEZ" "MOCA" "MOROVIS" "NAGUABO" "NARANJITO" "OROCOVIS" "PATILLAS" "PENUELAS" "PONCE" "QUEBRADILLAS" "RINCON" "RIO_GRANDE" "SABANA_GRANDE" "SALINAS" "SAN_GERMAN" "SAN_JUAN" "SAN_LORENZO" "SAN_SEBASTIAN" "SANTA_ISABEL" "TOA_ALTA" "TOA_BAJA" "TRUJILLO_ALTO" "UTUADO" "VEGA_ALTA" "VEGA_BAJA" "VIEQUES" "VILLALBA" "YABUCOA" "YAUCO")

#declare -a StringArray=("ADJUNTAS" "AGUADA" "AGUADILLA")



## We need to find what is the latest date available to us. easiest method is a curl query just for that. 
latestDate="$(curl -s -k "https://covid19datos.salud.gov.pr/estadisticas_v2/casos" --data-raw "CO_CLASIFICACION=Confirmado&CO_MUNICIPIO="| jq ' .POR_FECHA.FECHAS ' | tail -n 2 | head -n 1  | sed 's/\"//g' | sed 's/\,/ /g' | awk -F "-" '{print $2"/"$3"/"$1}'|sed 's/\ //g')"

## Create epoch values
dateval="$(date --date="$latestDate")"
dateCompileB="$(date --date="$dateval -$dayValue days"  +%m/%d/%Y)"
valueDaysPast="$(date --date="$dateCompileB 4:00:00" +"%s")"
oneDayPast="$(date --date="$latestDate 4:00:00" +"%s")"

## Date range for queries 
dateRange="&FE_RANGO%5B%5D=$valueDaysPast&FE_RANGO%5B%5D=$oneDayPast"

## Create date for current day 
currentDate="$(date +%d_%m_%Y )"

## Utilizing file outputs to reduce memory use 
FinalOutput="/tmp/Full_Chart$currentDate.csv"
tmpfileA="/tmp/logoutputA.csv"
tmpfileB="/tmp/logoutputB.csv"
tmpfileC="/tmp/logoutputC.csv"
ZeroFile="/tmp/zerofile.csv"
ZeroFileB="/tmp/zerofileB.csv"
ModFileA="/tmp/tmp1.mod"
ModFileB="/tmp/tmp2.mod"
totalA="/tmp/totalA.csv"
totalB="/tmp/totalB.csv"
unknownDataCalc="/tmp/unknownData.csv"
knownDataCalc="/tmp/knownData.csv"
unknownData="/tmp/unknown.csv"
tmpFileDir="/tmp/files/"


## down the line we run loops off these numbers
dayValuePlusOne=$(expr $dayValue + 1)


## Make a directory to store temp files used in calculations (dev/null added for if folder wasn't deleted and outputs error)
mkdir $tmpFileDir &>/dev/null

## If one of today's date exists, over-write with new data 
rm $FinalOutput &>/dev/null

## Define curl for non-municipality data queries 
FullCurl="$(curl -s -k "https://covid19datos.salud.gov.pr/estadisticas_v2/casos" --data-raw "CO_CLASIFICACION=Confirmado&CO_MUNICIPIO=$dateRange")"
FullMortality="$(curl -s -k 'https://covid19datos.salud.gov.pr/estadisticas_v2/defunc' -k  --data-raw "CO_REGION=" )"

## Output non-municipality data to file for use 
echo "$FullCurl" >>$totalA
echo "$FullMortality" >>$totalB

##Add Header 
echo "municipality," >> $tmpfileA

## Define how we want the dates to look
dateQuery="$(cat $totalA | jq ' .POR_FECHA.FECHAS '  | sed 's/\\//g' | sed 's/\"//g' | sed 's/\,/ /g' | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g' | awk -F "-" '{print $2$3$1}'|sed 's/\ //g')"

## Pull the rest of the dates 
for OUTPUT in $dateQuery
do
echo ",tst_pos_$OUTPUT,pb_pos$OUTPUT,mort_$OUTPUT,pbmort_$OUTPUT," >> $tmpfileA
done

## Add Mortality Date
cat $totalB |  jq ' .POR_FECHA.FECHAS '  |  tail -n 2|head -n 1 | sed 's/\\//g' | sed 's/\"//g' | sed 's/\,/ /g' | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g' |awk -F " " '{print $1'} | awk -F "-" '{print "tst_pos_"$2$3$1",pb_pos"$2$3$1",mort_"$2$3$1",pbmort_"$2$3$1}' >> $tmpfileA 

## Apply some last second formatting
cat $tmpfileA | sed  'H;1h;$!d;x;y/\n/,/' | sed 's/\,\,\,/\,/g'| sed 's/\,\,/\,/g' | head -n +2   >> $FinalOutput


## Start unknown data json array 
i=1;
for OUTPUT in $dateQuery
do
touch $tmpFileDir$i
echo "[" >> $tmpFileDir$i
((i++));
done

## Cleanup 
rm $tmpfileA 


######################
##### BEGIN LOOP #####
######################



## Using the above array, perform a loop
for val in "${StringArray[@]}"; do


#val="ADJUNTAS"

## Create curl variables for "confirmed" and "probable" case values 
CurlA="$(curl -s -k "https://covid19datos.salud.gov.pr/estadisticas_v2/casos" --data-raw "CO_CLASIFICACION=Confirmado&CO_MUNICIPIO=$val$dateRange" )" 
CurlB="$(curl -s -k "https://covid19datos.salud.gov.pr/estadisticas_v2/casos" --data-raw "CO_CLASIFICACION=Probable&CO_MUNICIPIO=$val$dateRange" )"

## Output curl data to temp file to process against and not run curl multiple times
echo $CurlB >> $tmpfileB
echo $CurlA >> $tmpfileA

#Format confired and probable case totals into array
confirmedCaseTotal="$(cat $tmpfileA | jq ' .POR_FECHA.ACUMULATIVO '| sed 's/\\//g' | sed 's/\"//g'  | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g' | tail -n +2| head -n -1)"
probableCaseTotal="$(cat $tmpfileB | jq ' .POR_FECHA.ACUMULATIVO '| sed 's/\\//g' | sed 's/\"//g'  | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g'| tail -n +2 | head -n -1)"
echo "$confirmedCaseTotal," >> $ModFileA
echo "$probableCaseTotal,0,0" >> $ModFileB

## Adding data to array for sum calculations
i=1; 
#for OUTPUT in $(cat $ModFileA  )

for OUTPUT in $dateQuery
do 
modDate="$(cat $ModFileA | head -n $i | tail -n 1)"
touch $tmpFileDir$i 
printf  '%s %s\n' "$modDate" >>$tmpFileDir$i ; 
((i++));
done

## Create "zero" columns data
zerofile="echo "0,""
cat $ModFileA | while read line; do $zerofile >> $ZeroFile; done

## add municipality to initial column, additional comma for blank mortality column
echo "$val" >> $tmpfileC

## combine all the columns together
paste -d ","  $ModFileA $ModFileB $ZeroFile $ZeroFile| sed  'H;1h;$!d;x;y/\n/,/' |  sed 's/\,,/,/g' >> $tmpfileC


## remove newlines and append to final
cat $tmpfileC | sed  'H;1h;$!d;x;y/\n/,/' >> $FinalOutput

## clean up temp files
rm $tmpfileA
rm $tmpfileB
rm $tmpfileC
rm $ZeroFile
rm $ModFileA
rm $ModFileB

done

####################
##### END LOOP #####
####################


## End unknown data json array 
i=1;
for OUTPUT in $dateQuery
do
echo "0 ]" >> $tmpFileDir$i

cat $tmpFileDir$i | jq '.|add' &>/dev/null >> $unknownDataCalc 
((i++));
done


## Get output of "all" to do unknown calculation with
cat $totalA | jq ' .POR_FECHA.ACUMULATIVO ' | sed 's/\\//g' | sed 's/\"//g'  | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g' | tail -n +2 | head -n  $dayValuePlusOne>> $knownDataCalc
#echo "0" >>$knownDataCalc
## subtract addition data of all known municipalities form total to get unknown values 
paste <(printf "%s\n" "$(cat $knownDataCalc )") <(printf "%s\n" "$(cat $unknownDataCalc )")  |
awk '{ print $1 - $2 }' | awk '{print $1","}'  >> $unknownData


## Mortality numbers are released a day ahead of other stats, so we output whatever the day value is plus 1 more to accomodate this. 
dayValuePlus=$(expr $dayValue + 3 )

##Mortality values 
cat $totalB  | jq ' .POR_FECHA.ACUMULATIVO ' | sed 's/\\//g' | sed 's/\"//g' | sed 's/\,/ /g' | sed 's/\[/ /g'| sed 's/\]/ /g'|sed 's/\  //g'|sed 's/\ //g' | tail -n +2 | tail -n $dayValuePlus   >>$ModFileA

## Create "zero" columns data, second round needed outside of loop to match mortality file length
zerofile="echo "0,""
cat $knownDataCalc | while read line; do $zerofile   >> $ZeroFile; done

## This bit is required for the additional below formatting 

cat $ZeroFile >> $ZeroFileB
echo "0,0" >> $ZeroFile 

## Add unknown line item
echo "Unknown" >> $tmpfileC

## compile the unknown row data 
paste -d "," $unknownData $ZeroFile $ModFileA  $ZeroFileB | sed  'H;1h;$!d;x;y/\n/,/' |  sed 's/\,,/,/g'|  sed 's/\,,/,/g' >> $tmpfileC 
#paste -d "," $ZeroFile $ZeroFile $ModFileA  $ZeroFileB | sed  'H;1h;$!d;x;y/\n/,/' |  sed 's/\,,/,/g'|  sed 's/\,,/,/g' >> $tmpfileC 

## remove newlines and append to final
cat $tmpfileC | sed  'H;1h;$!d;x;y/\n/,/' >> $FinalOutput

## Additional Cleanup
rm $totalA
rm $totalB
rm $ZeroFile
rm $ZeroFileB
rm $tmpfileC
rm $ModFileA
rm $unknownDataCalc
rm $unknownData
rm $knownDataCalc
rm $tmpFileDir/*
rmdir $tmpFileDir
