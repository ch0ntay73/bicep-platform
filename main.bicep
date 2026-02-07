// main.bicep
// Purpose: Orchestrate platform deployment at subscription scope:
// 1) Create a Resource Group
// 2) Create a VNet inside that Resource Group (via module)

targetScope = 'subscription'

// Inputs (come from params.dev.json / params.prod.json)
param location string
param rgName string
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetPrefix string
param vmRgName string
param vmName string
param nicName string
@secure()
param adminPassword string
param vmSize string = 'Standard_B1s'

// 1) Create the Resource Group (subscription scope module)
module rg './modules/rg.bicep' = {
  name: 'createRg'
  params: {
    name: rgName
    location: location
  }
}
// 2) create VM RG
module vmRg './modules/rg.bicep' = {
  name: 'createVmRg'
  params: {
    name: vmRgName
    location: location
  }
}

// 2) Create the VNet inside the RG (resource group scope module)
// NOTE: scope is set to the resource group we just created.
module vnet './modules/vnet.bicep' = {
  name: 'createVnet'
  scope: resourceGroup(rgName)
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: vnetAddressPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

// 3) Create Virtual Machine
module vm './modules/vm.bicep' = {
  name: 'createVm'
  scope: resourceGroup(vmRgName)
  params: {
    location: location
    vmName: vmName
    nicName: nicName
    subnetId: vnet.outputs.subnetId
    vmSize: vmSize
    adminPassword: adminPassword
  }
}
