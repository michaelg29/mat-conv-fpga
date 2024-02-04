 param (    
    [Parameter(Mandatory=$true)][string]$file,
    [Parameter(Mandatory=$true)][string]$tb, 
    [Parameter(Mandatory=$true)][string]$topEntity,     
    [Parameter(Mandatory=$true)][string]$vcd,
    [string]$stopTime="750ns"
 )

ghdl -a $file

ghdl -a $tb

ghdl -e $topEntity

ghdl -r $topEntity --vcd=$vcd --stop-time=$stopTime

gtkwave $vcd