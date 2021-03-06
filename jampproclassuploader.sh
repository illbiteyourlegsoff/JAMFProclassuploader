#!/bin/bash


#########################################
#
#
# This script is designed to upload a CSV to create AppleClassroom classes in JAMF pro
#   Created by Trey Howell August 2 2018
#
#
############################################



######Variables

####Account for access to API, needs ability to check accounts and read, write and create to Static groups, Device records, and Classes
apiuser="apiusername"
apipass="apipassword"
####comment out above and uncomment these if you want to ask for username and password
#apiuser="$(osascript -e 'Tell application "System Events" to display dialog "Enter the Username with API right" default answer "jsmith"' -e 'text returned of result' 2>/dev/null)"
#apipass="$(osascript -e 'Tell application "System Events" to display dialog "Enter the  Password for the account:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)"


####JSS Server, if Clustered may need to use a specific Server. I have had issues where not all Servers in cluster work with API calls
jssser="https://jssserver.com:8443"

####comment out above and uncomment these if you want to ask for JSS address
#jssser="$(osascript -e 'Tell application "System Events" to display dialog "Enter JSS address without ending slash" default answer "https://jss.org:8443"' -e 'text returned of result' 2>/dev/null)"


##comment out these lines if not using Sites
####getsite info
ste="$(osascript -e 'Tell application "System Events" to display dialog "Enter three digit site info" default answer ""' -e 'text returned of result' 2>/dev/null)"
#####hardcode Site info
#ste="TME"
#### for Logs being Created
loggedInUser=`ls -l /dev/console | awk '{print $3}'`
TIME=`date "+Date:%m-%d-%Y TIME:%H:%M:%S"`




                     ######################################################################
########################################do not modify below this line ###############################################
                     ######################################################################

#####ask for path for CSV file
INPUT="$(osascript -e 'Tell application "System Events" to  return POSIX path of (choose file with prompt "Select an CSV file")')"
###comment out above and uncomment below and put in path to hardcode.
#INPUT=$1
####commented out but may need to add a extra line for parsing
#head -N 1 "$INPUT" >> "$INPUT"
echo " " >> "$INPUT"
########Parseing the CSV file for DATA
SaveIFS=$IFS
IFS=","
while read serl stid stufrst stulst tchrnme tchrusrnme tchrnme1 tchrusrnme1 tchrnme2 tchrusrnme2 tchrnme3 tchrusrnme3 tchrnme4 tchrusrnme4 tchrnme5 tchrusrnme5  status
do

####Create log on Desktop in folder
mkdir -p /Users/$loggedInUser/Desktop/Classroom
echo "***********************************************************************" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo $TIME >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo " " >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"

#####random Gernerated data
rando=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-z' | head -c 8`
#############This part will add the Student info to the iPAd #################################################################################
	
#########strips out the beginning S if it exist, ignores it if it exists
serl2=`echo $serl | sed 's/^S\\(.*\\)/\\1/'`

###log
echo $serl2 >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
#####get ID of Student IPAD. Required for API Scripting
stuipdid=`curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevices/serialnumber/$serl2 | xpath /mobile_device/general/id[1] | sed 's,<id>,,;s,</id>,,' | tail -1`

####create student in VPP tab
echo "<user><name>"$stufrst  $stulst"</name><full_name>"$stufrst  $stulst"</full_name></user>" >  /tmp/vpp.xml
	
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/users/id/0 -T /tmp/vpp.xml -X POST >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"

	
###	Create XML to associate Student to iPad 
#echo "<mobile_device><general><site><name>"$ste"</name></site></general><location><username>"$stid"</username></location></mobile_device>" > /tmp/std.xml
echo "<mobile_device><general><site><name>"$ste"</name></site></general><location><username>"$stufrst  $stulst"</username><realname>"$stufrst  $stulst"</realname><real_name>"$stufrst  $stulst"</real_name><email_address>$rando</email_address></location></mobile_device>" > /tmp/std.xml
####upload the XML file to JSS 
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevices/id/$stuipdid -T /tmp/std.xml -X PUT >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	
######this Adds the Teacher in the Assigned to Attribute, Helps looking up student by Teacher named
##### Setting Variable for xml file with asset variable for Assigned to Teacher It is the extension attribute to be userd for later purposes ######
#can't have Spaces in usernames for Attributes, so this removes any spaces
tchrnmef=`echo "$tchrnme""_""$ste" | sed 's/ //g'` 
#tchrnmef=`echo $tchrnme`
####create XML for Teacher Attribute 
echo "<mobile_device><extension_attributes><extension_attribute><id>1</id><value>"$tchrnmef"</value></extension_attribute></extension_attributes></mobile_device>" > /tmp/nametcrt.xml

#####upload XML to JAMF PRO
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevices/id/$stuipdid -T /tmp/nametcrt.xml -X PUT >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"	

#############END OF This part will add the Student info to the iPAd  END OF #################################################################################
	
######create Static group and assign devices to group #############################################################

####create xml for static group
#echo "<mobile_device_group><name>"$tchrnmef"</name><is_smart>false</is_smart></mobile_device_group>" > /tmp/sticgrpc.xml
echo "<mobile_device_group><name>"$tchrnmef"</name><is_smart>false</is_smart><site><name>"$ste"</name></site></mobile_device_group>" > /tmp/sticgrpc.xml
########Upload Static Goup
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevicegroups/name/$tchrnmef -T /tmp/sticgrpc.xml -X POST >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"

########Add individual devices to Static Group just created
######create XML for Serial devices assigning to groups
echo "<mobile_device_group><mobile_device_additions><mobile_device><serial_number>"$serl2"</serial_number></mobile_device></mobile_device_additions></mobile_device_group>" > /tmp/sticgrp.xml

####upload Serials to JSS for Static Group
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevicegroups/name/$tchrnmef -T /tmp/sticgrp.xml -X PUT >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"

######END OF create Static group and assign devices to group END OF#############################################################

#########################add Static group to Class and create class #######################################################################




#########################END OF add Static group to Class and create class END OF#######################################################################

##############################This will add additional Teachers to the Class, The API requires all teachers be uploaded at same time, otherwise it will write over last one. This is why it checks for how many users. ####################

#####check see if 6th Teacher exits than add all 6 teachers
if [ "$tchrnme5" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher><teacher>"$tchrusrnme1"</teacher><teacher>"$tchrusrnme2"</teacher><teacher>"$tchrusrnme3"</teacher><teacher>"$tchrusrnme4"</teacher><teacher>"$tchrusrnme5"</teacher></teachers></class>" > /tmp/class3.xml

#####check see if 5th Teacher exits than add all 5 teachers
elif [ "$tchrnme4" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher><teacher>"$tchrusrnme1"</teacher><teacher>"$tchrusrnme2"</teacher><teacher>"$tchrusrnme3"</teacher><teacher>"$tchrusrnme4"</teacher></teachers></class>" > /tmp/class3.xml

#####check see if 4th Teacher exits than add all 4 teachers
elif [ "$tchrnme3" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher><teacher>"$tchrusrnme1"</teacher><teacher>"$tchrusrnme2"</teacher><teacher>"$tchrusrnme3"</teacher></teachers></class>" > /tmp/class3.xml

#####check see if 3rd Teacher exits than add all 3 teachers
elif [ "$tchrnme2" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher><teacher>"$tchrusrnme1"</teacher><teacher>"$tchrusrnme2"</teacher></teachers></class>" > /tmp/class3.xml

#####check see if 2nd Teacher exits than add all 2 teachers
elif [ "$tchrnme1" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher><teacher>"$tchrusrnme1"</teacher></teachers></class>" > /tmp/class3.xml

#####check see if 2nd Teacher exits than add all 2 teachers
elif [ "$tchrnme" != "" ];then
echo "<class><name>"$tchrnmef"</name><teachers><teacher>"$tchrusrnme"</teacher></teachers></class>" > /tmp/class3.xml

fi

#####upload the proper XML File for Class
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/classes/id/0 -T /tmp/class3.xml -X POST 

#####log info
cat /tmp/class3.xml >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log" 
##############################END OFThis will add additional Teachers to the Class, The API requires all teachers be uploaded at same time, otherwise it will write over last one. This is why it checks for how many users. END OF #######################################


########this is all logging, comment out to line 192 if not wanting logging
	#####testing to see variables Commented out but can be uncommented
	echo "Serial : $serl" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "Serial : $serl2" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "ipad id : $stuipdid" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "studentid : $stid" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "studentlast : $stulst" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "student first : $stufrst" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	
done < $INPUT
IFS=$SaveIFS
#####loop Ends here
echo "teacher : $tchrnme" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher id : $tchrusrnme" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher : $tchrnme1" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher id : $tchrusrnme1" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher : $tchrnme2" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
    echo "teacher id : $tchrusrnme2" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher : $tchrnme3" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher id : $tchrusrnme3" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher : $tchrnme4" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher id : $tchrusrnme4" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher : $tchrnme5" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
	echo "teacher id : $tchrusrnme5" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo "Finished" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo "*********************************************************************************************************************************************************************************************************************" >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo "   " >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo "   " >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"
echo "   " >> "/Users/$loggedInUser/Desktop/Classroom/$tchrnme.log"


######end of logging



######Get ID of static group, needed for adding to Class
grpid=`curl -k -s -u $apiuser:$apipass $jssser/JSSResource/mobiledevicegroups/name/"$tchrnmef" | xpath /mobile_device_group/id[1] | sed 's,<id>,,;s,</id>,,' | tail -1`


######Get Group so we can add static group to Class
echo "<class><site><name>"$ste"</name></site><mobile_device_group_ids><id>$grpid</id></mobile_device_group_ids></class>" > /tmp/class.xml

#####get ID for class
clssid=`curl -k -s -u $apiuser:$apipass $jssser/JSSResource/classes/name/$tchrnmef | xpath /class/id[1] | sed 's,<id>,,;s,</id>,,' | tail -1`

######add static group to Class Students
curl -k -s -u $apiuser:$apipass $jssser/JSSResource/classes/id/$clssid -T /tmp/class.xml -X PUT 

######CLEAN UP OF TMP FILES
sleep 3
rm /tmp/*.xml
