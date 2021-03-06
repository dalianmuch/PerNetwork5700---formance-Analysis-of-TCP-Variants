#Create a simulator object
set ns [new Simulator]

#set TCP variant & CBR rate from commandline
set variant [lindex $argv 0]
set cbrrate [lindex $argv 1]
set filename ${variant}_${cbrrate}

#Open the trace file (before you start the experiment!)
set tf [open ${filename}.tr w]
$ns trace-all $tf

#Define colors for different data flows
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
set nf [open ${filename}.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Close the trace file (after you finish the experiment!)
        close $tf
        #Execute NAM on the trace file
        #exec nam out.nam &
        exit 0
}

#Create 6 nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

#Create links between the nodes
$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns duplex-link $n5 $n2 10Mb 10ms DropTail
$ns duplex-link $n2 $n3 10Mb 10ms DropTail
$ns duplex-link $n3 $n4 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail

# set the queue size on the critical path
$ns queue-limit $n2 $n3 10

#Give node position (for NAM)
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n5 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n6 orient right-down

#create UDP client at n2 and sink at n3
set udp [new Agent/UDP]
$ns attach-agent $n2 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null

#create the datalink from n1 to n2 with Red color
$ns connect $udp $null
$udp set fid_ 2

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ ${cbrrate}mb
$cbr set random_ false

#set a TCP
if {$variant == "Tahoe"} {
	set tcp [new Agent/TCP]
} elseif {$variant == "Reno"} {
	set tcp [new Agent/TCP/Reno]
} elseif {$variant == "NewReno"} {
	set tcp [new Agent/TCP/Newreno]
} elseif {$variant == "Vegas"} {
	set tcp [new Agent/TCP/Vegas]
}

#attach tcp at n1
$ns attach-agent $n1 $tcp

#set Vegas parameter, in this configuration Vegas tries to keep between 1 and 3 packet queueed in the network
if {$variant == "Vegas"} {
	$tcp set v_alpha_ 1
	$tcp set v_beta_ 3
}

#create TCP sink at n4
set sink [new Agent/TCPSink]
$ns attach-agent $n4 $sink

#create the datalink from n1 to n2 with Blue color
$ns connect $tcp $sink
$tcp set fid_ 1

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP


#Schedule events for the CBR agents
$ns at 0 "$cbr start"
$ns at 1 "$ftp start"
$ns at 8 "$ftp stop"
$ns at 9 "$cbr stop"

#Call the finish procedure after 5 seconds of simulation time
$ns at 10 "finish"

#Print CBR packet size and interval
#puts "CBR packet size = [$cbr set packet_size_]"
#puts "CBR interval = [$cbr set interval_]"

#Run the simulation
$ns run
