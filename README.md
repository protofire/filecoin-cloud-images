# Overview

This repository contains a multicloud configuration for [Packer by Hashicorp](https://packer.io). Packer is designed to create so-called "golden" or "baked" cloud images - a set of disk snapshots with a set of predefined applications installed inside. These images are usually used to simplify onboarding of end users - one can simply reuse the existing images instead of spending time on manual installation of each component.

This project is developed under the [Protocol Labs (Filecoin project) grant](https://filecoin.io/grants/). The overall idea of the project is to use Packer to create a set of images in each cloud that will have Filecoin Lotus client preinstalled. 

It is known that the major problem for the developer community is the long synchronization of the node with the network. To solve this problem, cloud images includes the ledger of the network that represents the network state at the time the image was created. 

In order for the applications and the network state in the images to be kept up to date, two systems were created - a public CI system and a private CD system. CI and CD systems are described in the [CircleCI configuration file](.circleci/config.yml), however, the CD mechanism in CircleCI is not currently used; instead, it is transferred to the local Jenkins installation to reduce costs.

The CI mechanism is used to statically verify the cloud image configuration code, and the CD mechanism is used to create and publish the cloud images. At the moment, cloud images are available for three clouds - AWS, Azure and GCP. The installation instruction will be added here a bit later. 

To get more info about grant see [this PR](https://github.com/filecoin-project/devgrants/pull/116). 

# Setting CI/CD system in CircleCI

# Project management details

**The project management board is** [here](https://github.com/protofire/filecoin-cloud-images#workspaces/filecoin-cloud-images-5eda14bd52f3aafa934e8aea/board?repos=269589633)
