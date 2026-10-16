environment = "shared-services"
region      = "us-east-1"

repositories    = ["svc-api"]
replica_regions = ["sa-east-1"] # each region pulls from its own copy (DR)

force_delete = true # lab: destroy even with images; a real registry keeps false
