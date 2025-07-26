# Authentication
tenancy_ocid        = "ocid1.tenancy.oc1..aaaaaaaay7bzovkqr26wluubbxgtkoegdiz2utkmrchmglsn74ouqqyi72ba"
region              = "ap-sydney-1"
availability_domain = "Brdh:AP-SYDNEY-1-AD-1"

# Resource Configuration
compartment_id      = "ocid1.compartment.oc1..aaaaaaaa3bfgcrogwd3smdq7aeybl3lamkkfvtwmedfkt7whoizspclhghnq" # raptors_sandbox/damo-terraforming
ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1L8vO5zX7ZnWqoxbHh12KrG8nHxSDU1y+p39A7pm/Xu4Jp1IH8oyvCOhzkO5k8djbDCOo/BKmvKXq3tnKxcjvqSClLufDDQkUdeBa0RIcgvvQEuSNyWcKHPHN47i3vtJQu7ZTUdMMxu1LiaFUxH2Xrzxoeg9kvpqhjheGzgnowpUtAMiEt2welwADTo64888oyo+zv9csiD932I8CyglkxmVG6Jd7+HrmLR2iMPY1u/augi2NbCGIeoek7HeGMMPfXuKadJmRRBXE3tzQrk5nQiHOZYcpISGe9F1A5HXWoHzgtg6oTRP4Yo5gFuoRAxpS/6GsGgB1NP7CtA5dkb27"
instance_shape      = "VM.Standard.E4.Flex"
instance_image_ocid = "ocid1.image.oc1.ap-sydney-1.aaaaaaaa7l5t44goumyeu2ahf6cknh5lkfcetwzdagl5tj6e7gsoyjhdt7sa" # (Oracle-Linux-9.6-2025.06.17-0)
# display_name = "test-ext"
private_key_path = "/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"

# Network Configuration
vcn_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
