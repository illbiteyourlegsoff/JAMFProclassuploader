# JAMFProclassuploader

To build Classes in jamf pro for Apple Classroom

This is a uploader to Associate Students to their iPad, add the students to a Static group, Build the class by the teacher, and static group to the class, and add any additional Teachers. This uses jamf pro API REST. It was designed for schools not using Managed Apple IDs. 

This was originally built using AppleScript for App portability. This version is BASH. If you want applescript version let me know. 

HOW TO READ CSV File

Column A -- Serial number of Student iPad
column B -- Student AD login <-- not used in this version of script, but can be moodified too
Column C -- Student First Name
Column D -- Student Last Name
Column E -- Teachers name (HomeRoom Teacher -- it uses this as class name and group name)
Column F -- Teachers Directory shortname (It will do a AD/LDAP lookup via jamf pro)
Column G -- Second Teacher name (can be blank if not needed -- used if rotating teachers or Art/Music Teacher)
Column H -- Second Teacher directory shortname (can be blank if not needed -- will do a directory lookup)
Column I -- Third Teacher name (can be blank if not needed -- used if rotating teachers or Art/Music Teacher)
Column J -- Third Teacher directory shortname (can be blank if not needed -- will do a directory lookup)
Column K -- Fourth Teacher name (can be blank if not needed -- used if rotating teachers or Art/Music Teacher)
Column L -- Fourth Teacher directory shortname (can be blank if not needed -- will do a directory lookup)
Column M -- fifth Teacher name (can be blank if not needed -- used if rotating teachers or Art/Music Teacher)
Column N -- Fifth Teacher directory shortname (can be blank if not needed -- will do a directory lookup)
Column O -- Sixth Teacher name (can be blank if not needed -- used if rotating teachers or Art/Music Teacher)
Column P -- Sixth Teacher directory shortname (can be blank if not needed -- will do a directory lookup)

Any other columns will be ignored, but can be added
