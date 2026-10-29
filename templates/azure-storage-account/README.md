# azure-storage-account

Creates a resource group and a StorageV2 storage account (Standard_LRS) with TLS 1.2 minimum, HTTPS only, no public blob access and blob versioning on, plus one private container.

Attach an Azure cloud connector. Every input has a default; leave `subscription_id` empty to use the connector's subscription.

| Output | Description |
|---|---|
| `resource_group_name` | Name of the resource group |
| `storage_account_name` | Name of the storage account |
| `primary_blob_endpoint` | Primary blob endpoint |
| `container_name` | Name of the private container |
