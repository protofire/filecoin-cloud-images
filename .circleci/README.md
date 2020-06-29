# Setting CI/CD system in CircleCI

Here are the steps requires to start building this project at your own space:
1) Fork the project to your organization;
2) Setup account CircleCI.com;
3) Link GitHub to CircleCI and select forked project; 
4) Press "Start building;
5) Skip configuration file insertion as it is already inserted;
6) Go to `https://app.circleci.com/settings/project/github/<YOUR_ORGANIZATION>/filecoin-cloud-images/environment-variables` and setup environment variables according to the [environment variables](#environment-variables) section;
7) Go to the main project page and approve building of those pipelines that are marked as `<PROVIDER>-base`;
8) You can schedule automatic incremental image recreation. To do that - go to `.circleci/config.yml` and uncomment sections like:
```
          #    triggers:
          #      - schedule:
          #          cron: "0 0 * * *"
          #          filters:
          #            branches:
          #              only:
          #                - master
```
9) Next builds will be triggered at 12.00 AM on daily basis. You can adjust it by changing `cron: "0 0 * * *"` this line in accordance with Linux Cron system syntax;
10) A number of public settings such as disk size and AMI regions you can control by direct editing of Packer configuration files inside of each provider folder.

## Environment variables

### AWS provider-related variables

- [x] `AWS_ACCESS_KEY`;
- [x] `AWS_SECRET_KEY`.

To generate access and secret keys visit ["My security credentials"](https://console.aws.amazon.com/iam/home?#/security_credentials) page and press "Create access key". Save the keypair and enter as separate environment variables.

### Azure provider-related variables

- [x] `AZURE_CLIENT_ID`;
- [x] `AZURE_CLIENT_SECRET`;
- [x] `AZURE_TENANT_ID`.

To generate client's authenthication data do the following:
1) Go to the [App registrations panel of the Azure Active Directory](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps) and create a new application. This is an Azure version of Service Accounts;
2) Open the newly registered app. At the `Overview` tab save the `Application (client) ID` and `Directory (tenant) ID` values;
3) Go to the `Certificates and Secretes` tab. Press `New client secret` to generate the secret.
- [x] `AZURE_SUBSCRIPTION_ID` - open the [Subscriptions blade](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) and copy the ID of the subscription which you would like to use in this project;
- [x] `AZURE_RESOURCE_GROUP_NAME` - you will need a separate resource group to create resources at. Go to [resource group management dashboard](https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups) and click `Add` to create a new resource group;
- [x] `AZURE_STORAGE_ACCOUNT`;
- [x] `AZURE_STORAGE_ACCOUNT_CONTAINER`.

This solution will create a `.vhd` disks as an output and store them at Azure storage account. Thus, you will need to provide scripts with storage account identification data:
1) Go to the [Azure storage accounts management dashboard](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Storage%2FStorageAccounts);
2) Click "Add" to create new storage account. Make it public or private according to your needs;
3) Open created storage account and select `Containers`;
4) Press `+ Container` to add a new container for VHDs;
5) Set the name of the azure storage account as `AZURE_STORAGE_ACCOUNT` and container name as `AZURE_STORAGE_ACCOUNT_CONTAINER`.

### GCP provider-related variables

- [x] `GCP_ACCOUNT` - JSON one-liner that contains authenthication information for GCP. 

To get JSON do the following:
1) Open the [Service Accounts tab at GCP IAM](https://console.cloud.google.com/iam-admin/serviceaccounts);
2) Press "Create service account";
3) Set the name and click `Create`;
4) Press `⋮` button which is on the same line as the created service account;
5) Press `Create key`. Select JSON and hit `Create`;
6) Go to [IAM panel](https://console.cloud.google.com/iam-admin/iam) and assign the `Compute Instance Admin (v1)`, `Service Account User` and `Storage Admin` roles to the created service account;
7) Convert saved JSON file into one-liner. For that purpose you can use `jq`. For example: `jq -c . account.json`.
- [x] `GCP_PROJECT` - the project where images will be built. The account specified at `GCP_ACCOUNT` variable must have access to the Compute API. Compute API must be enabled;
- [x] `GCP_STORAGE` - storage account where images will be published. The account specified at `GCP_ACCOUNT` variable must have access to the Storage API. Storage API must be enabled.

### Filecoin-related variables

- [x] `BRANCHES` (comma-separated values) - set of branches that should be searched for tags to build Lotus node from. Currently we are building `interopnet` and `master` branches, which stands for `interop` and `test` networks. The variable's value in our case will be equal to `interopnet,master`.

### Optional variables:

- [ ] `SLACK_WEBHOOK` - URL to the webhook that allows posting building information to the slack channels.
Note: To make build end successfully - comment out `- slack/status` lines if you haven't set the `SLACK_WEBHOOK` variables.
