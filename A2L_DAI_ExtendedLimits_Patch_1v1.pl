require Cwd;		# make Cwd:: accessible
$path = Cwd::getcwd();  

$A2L_FILE = $ARGV[0].".a2l";
$PATH_BIN = $ARGV[1];
$PATH_A2L = $ARGV[1].$A2L_FILE;
$PATH_FKTLIST = $ARGV[2];


$result_file = $PATH_BIN.$ARGV[3]."_customer_delivery.a2l ";


#print "\n Weiter <RETURN>";
#chop ( $input = <STDIN> );

print "\n\nStart-Time: ".localtime()."\n\n";

$version = "1v1";

@FktListe;

@ParameterList;
@temp_ParameterList;

@completeA2L;
@strippedA2L;

$line_count = 0;

####################################################################################################################
#  Version 1.0  2016-05-17 DGS-EC/ECD3-Gu  Initial Version A2L Adress Parser
#  Version 1.1  2016-05-17 DGS-EC/ECD3-Gu  Version for OM608 with XML-Toolchain and other projects. Renamed output
####################################################################################################################

##################################################################################
#  Begin reading Daimler function list
##################################################################################
{
open(FKTLIST,   "< $PATH_FKTLIST")            	or die "can't open $PATH_FKTLIST: $!";

LINE: while (<FKTLIST>) 
	{
		local $line = $_;
		
		$line = substr($line,0,index($line,","));
		
		push(@FktListe,$line."\n");
		
	}
	print "A2L-file with the following Functions will be generated: \n\n";
	print @FktListe;
	print "\n\n";
	print "---------------------------------------------------------\n\n\n";
	
close(FKTLIST)                  or die "can't close $PATH_FKTLIST: $!";
}


##################################################################################
#  Begin reading A2L-File
##################################################################################
{
open(A2L,   "< $PATH_A2L")            	or die "can't open $A2L_FILE: $!";
open(RESULT,   "> $result_file")      	or die "can't open $result_file: $!";

local $Error;
local $state = 0;
local $substate = 0;
local $type = 0;
local $tempString = "";
local $tempString2 = "";
local $lineNumber = 0;
local $adress_dec = 0;
local $errorLineNumber = 0;
local $totalError = 0;
local $match = 0;
local $match2 = 0;


print "Analyzing ".$A2L_FILE." ! Please wait....\n";
print "\n--------------------------------------------------\n";


$Error = 0;

## parse complete A2L File. Store each line in @completeA2L for later use. Parse desired functions Blocks for Parameters and Variables on the first scan.
LINE: while (<A2L>) 
	{
		local $line = $_;
		
		push(@completeA2L,$line);
		$line_count++;
		
		if(/\/begin FUNCTION/)
		{
			$state = 1;	## Function Block starts
		}
		elsif(/\/end FUNCTION/)
		{			
			$state = 0; ## Function Block end
			
		}
		
		if($state > 0) ## if within a Function block
		{
			if($state == 1)
			{
				$state = 2; ## Move to next state: compare Function name
			}
			else
			{
				if(/^$/)
				{
					#ignore empty lines
				}
				elsif($state == 2) ## Compare Function name
				{
					$state = 3;
					foreach my $temp01 (@FktListe)
					{
						chomp($temp01);
						$tempString = $line;
						chomp($tempString);
						$tempString = substr($tempString,rindex($tempString," ")+1);
						if(("\;".$tempString."\;") =~ ("\;".$temp01."\;"))	## Search for subsections, e.g. (.sbss.var0)
						{
							print "Function found: >>".$tempString."<< !!!!!!!!!!!\n";
							$state = 4;	## requested function found
						}
						
					}
					if($state == 3)
					{
						$state = 100; ## ignore this function
					}
				}
				elsif($state == 4) ## Function found, aquire Measurement and Parameter names
				{
					if($line =~ "\/begin DEF_CHARACTERISTIC")
					{
						$state = 5;	## collect Parameters
					}
				}
				elsif($state == 5) ## collect Parameters
				{
					if($line =~ "\/end DEF_CHARACTERISTIC")
					{
						$state = 4;	## end collect Parameters, back to main state 4
						push(@ParameterList,@temp_ParameterList);
						@temp_ParameterList = ();
					}
					else
					{
						$tempString = $line;
						chomp($tempString);						
						
						while(length($tempString) > 0)
						{
							$tempString2 = substr($tempString,rindex($tempString," ")+1);
							if(length($tempString2) > 0)
							{
								push(@temp_ParameterList,$tempString2);
							}
							$tempString = substr($tempString,0,rindex($tempString," "));
						}
					}
					
				}
			}
		}
	}

$state = 0;
	
## Now that we have the desired Parameters and Variables, create the stripped A2L-File
print "\n\nGenerating A2L-File...Please Wait!!\n";
printf "Total Lines  : %12d\n",$line_count;

local $line_count_i = 0;

foreach my $temp_line (@completeA2L)
{
	$line_count_i++;
	printf ("Lines parsed : %12d\r", $line_count_i) ;	
	## take over Header
	if($state == 0)
	{
		if(($temp_line =~ "\/begin CHARACTERISTIC")||($temp_line =~ "\/begin AXIS_PTS"))
		{
			$state = 1; ## proceed to Parameter phase
			push(@strippedA2L,$temp_line);
		}
		else
		{
			push(@strippedA2L,$temp_line);
		}
	}
	elsif($state == 1)
	{
		if($temp_line =~ /^$/)
		{
			push(@strippedA2L,$temp_line);
		}
		else
		{
			$tempString = $temp_line;
			chomp($tempString);
			$tempString = substr($tempString,rindex($temp_line," ")+1);
			
			#special handling for Arrays
			$tempString =~ s/\[/_/s;
			$tempString =~ s/\]/_/s;

			foreach my $tempParamName (@ParameterList)
			{
				
				#special handling for Arrays
				$tempParamName =~ s/\[/_/s;
				$tempParamName =~ s/\]/_/s;
				
				if((";".$tempParamName.";") =~ (";".$tempString.";"))
				{
					$match = 1;
				}
					#if(($tempParamName =~ /ExhMgT.*\[0\]/)&&($tempString =~ /ExhMgT.*\[0\]/))
					#{
					#	print ">>".$tempParamName."<<\n";
					#	print ">>".$tempString."<<\n";

						#print ">>".$tempParamName."<<\n";
						#print ">>".$tempString."<<\n";
						#$tempParamName = quotemeta($tempParamName);
						#print $tempParamName."\n";
						#print $tempString."\n";
						#if(("\;".$tempParamName."\;") =~ ("\;".$tempString."\;"))
						#{
	#								print "Match!!!!\n";
	#							}
	#							chop ( $input = <STDIN> );
					#}
			}
			if($match == 1)
			{
				$state = 2;
				#print "Match    :".$tempString."\n";
			}
			else
			{
				$state = 0;
				#print "No Match :".$tempString."\n";
			}
			
			push(@strippedA2L,$temp_line);
			$match = 0;
			#chop ( $input = <STDIN> );
		}
	}
	elsif($state == 2)
	{
		if($temp_line =~ "EXTENDED_LIMITS")
		{
			##skip EXTENDED_LIMIT
		}
		else
		{
			push(@strippedA2L,$temp_line);
		}
		
		if(($temp_line =~ "\/end CHARACTERISTIC")||($temp_line =~ "\/end AXIS_PTS"))
		{
			$state = 0;
		}

	
	}
}

print RESULT @strippedA2L;

close(RESULT)              	or die "can't close $result_file: $!";	
close(A2L)                  or die "can't close $A2L_FILE: $!";
}

print "\n\nEnd-Time: ".localtime()."\n";

{exit 0;}
