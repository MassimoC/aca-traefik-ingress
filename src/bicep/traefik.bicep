param appName string
param mountedStatic string = 'traefikstatic'
param mountedDynamic string = 'traefikconfig'
param isExternalIngress bool = true
param location string = resourceGroup().location
param environmentId string
param minReplica int = 1
param maxReplica int = 1
param tag string = 'v2.10.1'
param env array = []


resource containerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: appName
  location: location
  properties: {
    environmentId: environmentId
    configuration: {
      activeRevisionsMode:'Single'
      ingress: {
        allowInsecure:true
        external: isExternalIngress
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          image: 'library/traefik:${tag}'
          name: appName
          env: env
          volumeMounts: [
            {
              volumeName: 'azure-file-static'
              mountPath: '/etc/traefik'
            }
            {
              volumeName: 'azure-file-dynamic'
              mountPath: '/etc/traefik/dynamic'
            }
          ]
          resources:{
            cpu: json('0.5')
            memory:'1Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplica
        maxReplicas: maxReplica
        rules:[
          {
            name: 'http'
            http:{
              metadata:{
                concurrentRequests: '200'
              }
            }
          }
        ]
      }
      volumes:[
        {
          name:'azure-file-static'
          storageType:'AzureFile'
          storageName: mountedStatic
        }
        {
          name:'azure-file-dynamic'
          storageType:'AzureFile'
          storageName: mountedDynamic
        }
      ]
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
