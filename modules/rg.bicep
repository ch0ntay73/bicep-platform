// modules/rg.bicep
// Purpose: Create a resource group

targetScope = 'subscription'

// Inputs
param name string
param location string

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
}

// Outputs
output rgName string = rg.name
output rgId string = rg.id
