$tleValid=0;

#special case known-bad orbits which arent otherwise filtered
$bad{"2LINE_ELEM_2010050.03.gz"}=1;

while(<>) {
  $line=$_;
  if($line=~/(\S{10})\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2}(.\d+)?).*(2LINE_.*)/) {
    $chmod=$1;
    $link=$2;
    $uid=$3;
    $gid=$4;
    $size=$5;
    $year=$6;
    $month=$7;
    $day=$8;
    $hour=$9;
    $min=$10;
    $sec=$11;
    $fn=$13;
    @mlen=(31,28,31,30,31,30,31,31,30,31,30,31);
    $doy=0;
    for($i=0;$i<$month-1;$i++) {
      $doy+=$mlen[$i];
    }
    $doy+=$day;
    $ydfile=($year-2000)*1000+$doy+$hour/24+$min/1440+$sec/86400;
    $name=<>;
    $name=~s/\n//g;
    $name=~s/^\s+//g;
    $name=~s/\s+$//g;
    if(length($name)>18) {
      $name=substr($name,0,18);
    }
  } elsif($line=~/^1 \d{5}U \d{5}[A-Z]   (.{14})/) {
    $line1=$line;
    $ydtle=$1;
    $ydtle=~s/ /0/g;
    if(($ydtle-0.25)<$ydfile & $ydtle>10042) {
      unless(exists($bad{$fn})) {
        printf "%-18s%14.8f %s\n",$name,$ydfile,$fn;
        print $line1;
        $tleValid=1;
      }
    } 
  } elsif($line=~/^2 \d{5}/) {
    $line2=$line;
    if($tleValid) {
      print $line2;
      $tleValid=0;
    }
  }
}

