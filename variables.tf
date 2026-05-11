variable "vpc_id" {
  default = "vpc-08dd1e63f98b2adaf"   # Cambia por tu VPC
}

variable "subnet_ids" {
  type    = list(string)
  default = [
    "subnet-065e8b30cff0a381e",       # Cambia por tus subnets (mínimo 2 para el ALB)
    "subnet-04ef391c154dd641e"
  ]
}

variable "ami_id" {
  default = "ami-02dfbd4ff395f2a1b"   # Amazon Linux 2023
}

variable "key_name" {
  default = "Chefgptkey2"         # Cambia por tu key pair
}

variable "instance_type" {
  default = "t3.micro"
}