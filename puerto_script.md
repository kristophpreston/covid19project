# puerto_script
PURPOSE
This script is intended to pull Covid-19 Death and Case data from the Puerto Rico state website @ https://covid19datos.salud.gov.pr/ and output it into a formatted CSV file. 

DEPENDENCIES:
JQ

REQUIREMENTS
The purpose of the Unknown row case total is to calcuate the difference between the sum of cases reported by each county and the total reported by the state. This difference constitutes "unknown cases" which are cases that cannot be assigned to any given municipality. As this number flucuates on a regular bases as unknowns are properly/reassigned, it will generally not adhere to any pattern of progression and should remain relatively stable. Puerto Rico does not report deaths for individual counties, only regions, therefore death numbers are placed in the unknown row are the totals for the state, and are unknown as they cannot be attributed to any individual county. 

ISSUES/BUGS
State began reporting Deaths on the 17Mar2020, and Cases on 1Mar2020. This is causing an issue in the Unknown row if a pull is done past 17Mar2020. 
Script does not output proper values if run for a scope for 60 days or less. Unclear why at this time.
State reports Deaths 1 day before cases and both on a delay, so the script is currently outputting a death value with no associated case data.

PLANNED UPDATES
Resolve Unknown row bug.
Remove extra death data from end of runs. 
Convert script to Python.
