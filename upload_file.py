#!/usr/bin/env python
#Simple proof of concept script
#for uploading files to the rackspace
#Cloud Files service
#Using the Pyrax API

from __future__ import print_function
import os
import pyrax
import pyrax.exceptions as exc
import pyrax.utils as utils

pyrax.set_setting("identity_type", "rackspace")
#path to your cloud credentials file:
creds_file = os.path.expanduser("~/.rackspace_cloud_credentials")
pyrax.set_credential_file(creds_file)
cf = pyrax.cloudfiles

cont_name = "traiano"
cont = cf.create_container(cont_name)

#path to the thing to be uploaded (in this case a fat vhd file)
tmpname = "/var/data/a91c5ce9-37a4-4d9d-8bb5-27710bd0cc54.vhd"

nm = os.path.basename(tmpname)
print("Uploading file: %s" % nm)
cf.upload_file(cont, tmpname, content_type="text/text")

# Let's verify that the file is there
obj = cont.get_object(nm)
print()
print("Stored Object:", obj)
print("Retrieved Content:")
print()

# Get the contents
print(obj.get())
print()

#Optionally, clean up the file
#from the CloudFiles container as follows:
# Clean up
#cont.delete(True)
