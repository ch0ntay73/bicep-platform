// modules/vnet.bicep
// Purpose: Create a VNet with a single subnet

targetScope = 'resourceGroup'

// Inputs
param vnetName string
param location string
param addressPrefix string
param subnetName string
param subnetPrefix string


resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

// Outputs (optional)
output vnetId string = vnet.id
output vnetNameOut string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
