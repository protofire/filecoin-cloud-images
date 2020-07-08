# Overview

This repository contains a multicloud configuration for [Packer by Hashicorp](https://packer.io). Packer is designed to create so-called "golden" or "baked" cloud images - a set of disk snapshots with a set of predefined applications installed inside. These images are usually used to simplify onboarding of end users - one can simply reuse the existing images instead of spending time on manual installation of each component.

This project is developed under the [Protocol Labs (Filecoin project) grant](https://filecoin.io/grants/). The overall idea of the project is to use Packer to create a set of images in each cloud that will have Filecoin Lotus client preinstalled.

It is known that the major problem for the developer community is the long synchronization of the node with the network. To solve this problem, cloud images includes the ledger of the network that represents the network state at the time the image was created.

In order for the applications and the network state in the images to be kept up to date, two systems were created - a public CI system and a private CD system. CI and CD systems are described in the [CircleCI configuration folder](.circleci/), however, the CD mechanism in CircleCI is not currently used; instead, it is transferred to the local Jenkins installation to reduce costs.

The CI mechanism is used to statically verify the cloud image configuration code, and the CD mechanism is used to create and publish the cloud images. At the moment, cloud images are available for three clouds - AWS, Azure and GCP. The installation instruction will be added here a bit later.

To get more info about grant see [this PR](https://github.com/filecoin-project/devgrants/pull/116).

 
# Cloud images instructions

Filecoin has a set of cloud images in each of the major clouds, such as Amazon Web Services (AWS), Google Cloud Platform (GCP), and Microsoft Azure. 

A Filecoin image is an Ubuntu-based image with a [Lotus node](https://lotu.sh) and [Powergate](https://github.com/textileio/powergate) installed. An advantageous difference of this installation method compared to the others is in the synchronization time. Cloud images are provided with the node state bundled into an image. It is automatically renewed with a continuous delivery mechanism on a daily basis. The average synchronization time will be only around 30 minutes versus days or even weeks when performing plain installation. One can get these images to start using the Filecoin test network almost immediately.


Installation is cloud-specific.


## AWS


To get an AWS image, you will have to complete the following steps: 

1) Open your [aws console](https://console.aws.amazon.com/) at the [AMI's page](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;search=filecoin;sort=name).
2) Choose a region (US East 2 , AP South 1 and EU Central 1 are currently supported). 
3) Select `Public AMI` at the filters dropdown menu and search for Filecoin images. 
4) At the search bar, you can add 711012187398 as an image owner to ensure that Filecoin images are official and to shorten the output. All the official images are named as `filecoin-<branch>-<tag>-<creation_date>`, where `<tag>` is one of the tags from [our GitHub](https://github.com/filecoin-project/lotus/tags), and `<creation_date>` is the accurate date and time when the images were created to reflect the timestamp of the Lotus chain. Note that some of the old tags might be missing, as there is no need to keep the old releases.
5) Select an appropriate image and press the `Launch` button.


**Warning!** Beware of fakes. Make sure AMI is owned by the 711012187398 account before launch.


You can find more detailed steps [here](https://aws.amazon.com/premiumsupport/knowledge-center/launch-instance-custom-ami).


## GCP

To create a Filecoin VM on GCP, you need to create a custom image in your project from an archive stored on our Google Storage account and launch a VM from this custom image.


To create a custom image, go to `Compute engine`, click `Images`, and then click `Create image`. Fill out all the necessary fields. For more instructions, check out this [article](https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#bundle_image).
For example:
1) Set `Filecoin` as an image name.
2) Select `Cloud Storage file` as a source for an image and specify the following link as a cloud storage file link `filecoin/filecoin-<tag>-latest.tar.gz`. Get `<tag>` from [our GitHub](https://github.com/filecoin-project/lotus/tags).
3) Click *Create*


Once the image is created, you can launch a VM from this custom image. To do so, go to `Compute Engine`, click `VM Instances`, and then click `Create`. Change the boot disk to the custom image created in the first step. Adjust a VM type to fill out node’s technical requirements. Press `Create` to complete the process.


## Microsoft Azure

To create a VM on Microsoft Azure, you will have to complete the following steps:


1) Log into your Azure account on https://portal.azure.com 
2) Create a storage account. You can also use the existing account that will enable you to upload a virtual hard disk (VHD) in the next steps. 
3) Create a container inside of the storage account. Make it either public or private according to your needs.
4) To get cloud images, you will need to figure out the current URL to an image disk. There is a single OS and a single data disk that you are looking for.

Open the following link substituting the variables in `${}` brackets: https://filecoin.blob.core.windows.net/system?restype=container&comp=list&maxresults=1&prefix=Microsoft.Compute/Images/filecoin/filecoin-${BRANCH}-${TYPE}Disk 

, where `${BRANCH}` is either `master` for the test network or `interopnet` for the interop network, and `${TYPE}` is `os` and `data`. For example, to find the OS disk for the test network, the link will look the following way: https://filecoin.blob.core.windows.net/system?restype=container&comp=list&maxresults=1&prefix=Microsoft.Compute/Images/filecoin/filecoin-master-osDisk 
You will receive the XML array when opening the link above:
```
<EnumerationResults ContainerName="https://filecoin.blob.core.windows.net/system">
...
<Blobs>
<Blob>
<Name>Microsoft.Compute/Images/filecoin/filecoin-master-dataDisk-0.4847ddfa-f5be-4e12-8936-05c9815cb7a0.vhd</Name>
**<Url>https://filecoin.blob.core.windows.net/system/Microsoft.Compute/Images/filecoin/filecoin-master-dataDisk-0.4847ddfa-f5be-4e12-8936-05c9815cb7a0.vhd</Url>**
...
</Blob>
</Blobs>
<NextMarker/>
</EnumerationResults>
```
You are interested in the `URL` parameter, which will be required later. Note down URLs for both the OS and data disks.

5. Download, install, and login to [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
6. Copy the Filecoin disks into your storage account using Azure CLI.


```
az storage blob copy start --source-uri $URL \
--connection-string $CONNECTION_STRING \
--destination-container $CONTAINER_NAME\
--destination-blob filecoin-${TYPE}.vhd
```


, where `${CONNECTION_STRING}` is a connection string for the storage account you have created at step 2, `${URL}` is the address of the disk, ${CONTAINER_NAME} is the name of the container created at step 3, and ${TYPE} is the disk type (`os` or `data`).
You will have to execute this command twice—once per disk type. 

**Note** that the links get updated daily at 9.00 PM UTC. The disk copy operation will take some time, so make sure to copy the disk before 9.00 PM, as your link will be lost, and the copy operation interrupted.


7) Once the VHDs are copied, go to [the MS Azure Image creation tab](https://portal.azure.com/#create/Microsoft.Image-ARM) and specify the uploaded VHDs as `Image Source`. Make sure to specify the OS disk as the image source for the OS, and data disk as source of the additional disk.


8) The last step is to deploy the [Filecoin VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal), using a custom image that you have created at the previous step.

### Using Azure VHD disk in other virtualization systems 
VHD is one of the most popular disk formats that are supported by a number of major virtualization providers — cloud and on-premises ones. Instead of performing the copy operation, you can use the link provided at step 4 to download both data and OS disks to your system, and then use it as you would use any other generalized VM disk snapshot. 


# Operation instructions


Launched automatically, both Lotus and Powergate are installed as services inside of an image. These services can be managed via SystemD.


Use the `sudo systemctl status/start/stop/restart/enable/disable` command with the `lotus-node.service` or `powergate.service` arguments to manipulate the Lotus node or the Powergate service accordingly.


When installing the node, make sure the RPC port (`1234/TCP`) is secured. The node is installed in accordance with the Lotus best practices. However, it is worth remembering that end users are responsible for securing nodes on their own.

# Project management details

**The project management board is** [here](https://github.com/protofire/filecoin-cloud-images#workspaces/filecoin-cloud-images-5eda14bd52f3aafa934e8aea/board?repos=269589633).
