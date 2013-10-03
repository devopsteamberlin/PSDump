$spAssignment = Start-SPAssignment
$mylist = (Get-SPWeb -identity http://sp2010riyaz:3877/Contracts -AssignmentCollection $spAssignment).Lists["Document Updates"]

$item1 = $mylist.Items.Add()
$item1["Title"] = "Item-1"
$item1["URL"] = "http://abc.com"
$item1["Document Version"] = "1.0.1"
$item1["Check-in Comment"] = "Comment-1"
$item1["Type of Change"] = "Adjustment"
$item1.Update()

$item2 = $mylist.Items.Add()
$item2["Title"] = "Item-2"
$item2["URL"] = "http://abc.com"
$item2["Document Version"] = "1.0.2"
$item2["Check-in Comment"] = "Comment-2"
$item2["Type of Change"] = "GA Submission"
$item2.Update()

$item3 = $mylist.Items.Add()
$item3["Title"] = "Item-3"
$item3["URL"] = "http://abc.com"
$item3["Document Version"] = "1.0.3"
$item3["Check-in Comment"] = "Comment-3"
$item3["Type of Change"] = "Indexed CP"
$item3.Update()

$item4 = $mylist.Items.Add()
$item4["Title"] = "Item-4"
$item4["URL"] = "http://abc.com"
$item4["Document Version"] = "1.0.4"
$item4["Check-in Comment"] = "Comment-4"
$item4["Type of Change"] = "Settlement"
$item4.Update()

$item5 = $mylist.Items.Add()
$item5["Title"] = "Item-5"
$item5["URL"] = "http://abc.com"
$item5["Document Version"] = "1.0.5"
$item5["Check-in Comment"] = "Comment-5"
$item5["Type of Change"] = "Settlement"
$item5.Update()

Stop-SPAssignment $spAssignment