# Publisher-auto-register

This repository contains 2 script that can be used in conjunction to automatically create and registr a Publisher and unregister and delete a Publisher directly from the publisher machine.

The script "aut-register.sh" creates the Publisher object in the tenant, retrieves the Publisher Token and register the Publisher, and it can be used in the following way:
```
sudo ./auto-register.sh -u <tenant_FQDN> -a <APIv2_Token> -n <Publisher_Name> [-t <Publisher_Tags_comma_separated>] [-g <publisher_upgrade_profile_external_id>
```
where the parameters **-u**, **-a** and **-n** are mandatory.

The parameters are:
* -u : Tenant FQDN, for instance ***mytenant.goskope.com***, or ***mytenant.eu.goskope.com***
* -a : APIv2 Token : APIv2 token that was previously created on the tenant. The APIv2 token used for both the scripts requires the following endpoints:
*   /api/v2/infrastructure/publisherupgradeprofiles "Read"
*   /api/v2/infrastructure/publishers	"Read + Write"
* -n : Publisher Name, for instance ***Publisher-AWS-1***
* -t : Comma-separated list of Publisher Tags, for instance ***tag1,tag-2,tag--3*** with no special characters or spaces
* -g : Publisher Upgrade Profile "external_id", the "external_id" of a valid Publisher Upgrade Profile. If not provided, or it not-existing, the registration defaults to the Default Upgrade Profile


The script "auto-unregister.sh" deletes the Publisher in the tenant (provided there are no NPA Applications directly assigned to it) and deletes the registration configuration on the Publisher machine (unregistering it), and it can be used in the following way:
```
sudo ./auto-unregister.sh -u <tenant_FQDN> -a <APIv2_Token>
```
where the parameters **-u**, **-a** are mandatory.

The scripts can be downloaded directly from the Publisher using:
```
curl -s https://raw.githubusercontent.com/sartioli/Publisher-auto-register/main/auto-register.sh --output ./auto-register.sh
curl -s https://raw.githubusercontent.com/sartioli/Publisher-auto-register/main/auto-unregister.sh --output ./auto-unregister.sh
chmod 777 ./auto-register.sh
chmod 777 ./auto-unregister.sh

```
The scripts must be downloaded and executed from the home directory of the Publisher (the same directory where the folder "resources" is located), the same path used after exiting the "publisher_wizard" upon login. 
