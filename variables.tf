variable "cluster_name" {
	type = string
}


variable "environment" {
	type = string
	default = "dev"
}

variable "alb_name" {
	type = string
}


variable "bucket_name" {
	type = string
}

variable "cidr_block" {
	type = string
}

variable "sg_name" {
	type = string
}
