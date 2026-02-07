@description('Location for all resources')
param location string

@description('Name for the VM')
param vmName string

@description('Resource ID of the subnet to attach the NIC to')
param subnetId string

@description('Size of the VM')
param vmSize string = 'Standard_D2s_v5'

@description('OS type: windows or linux')
@allowed([
  'windows'
  'linux'
])
param osType string = 'windows'

@secure()
@description('Admin password (Windows) or password for Linux if disablePasswordAuthentication=false')
param adminPassword string

@description('Admin username')
param adminUsername string = 'azureadmin'

@description('Create a Public IP and attach to NIC')
param enablePublicIp bool = false

@description('Tags to apply')
param tags object = {}

@description('Image reference (override defaults if needed)')
param imagePublisher string = (osType == 'windows') ? 'MicrosoftWindowsServer' : 'Canonical'
param imageOffer string     = (osType == 'windows') ? 'WindowsServer'         : '0001-com-ubuntu-server-jammy'
param imageSku string       = (osType == 'windows') ? '2022-datacenter-azure-edition' : '22_04-lts-gen2'
param imageVersion string   = 'latest'

@description('OS disk type')
param osDiskSku string = 'Premium_LRS'

@description('Optional managed data disks in GB, e.g. [128, 256]')
param dataDiskSizesGB array = []

// --------------------
// Networking
// --------------------
var nicName = '${vmName}-nic01'
var pipName = '${vmName}-pip01'

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (enablePublicIp) {
  name: pipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: enablePublicIp ? { id: pip.id } : null
        }
      }
    ]
  }
}

// --------------------
// Data disks (optional)
// --------------------
resource dataDisks 'Microsoft.Compute/disks@2024-03-02' = [for (sizeGB, i) in dataDiskSizesGB: {
  name: '${vmName}-data${i + 1}'
  location: location
  tags: tags
  sku: {
    name: osDiskSku
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: sizeGB
  }
}]

// --------------------
// VM
// --------------------
resource vm 'Microsoft.Compute/virtualMachines@2024-03-02' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: osType == 'windows'
      ? {
          computerName: vmName
          adminUsername: adminUsername
          adminPassword: adminPassword
        }
      : {
          computerName: vmName
          adminUsername: adminUsername
          adminPassword: adminPassword
          linuxConfiguration: {
            disablePasswordAuthentication: false
          }
        }

    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskSku
        }
      }
      dataDisks: [for (d, i) in dataDisks: {
        lun: i
        name: d.name
        createOption: 'Attach'
        managedDisk: {
          id: d.id
        }
      }]
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output vmId string = vm.id
output nicId string = nic.id
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = enablePublicIp ? pip.properties.ipAddress : ''
