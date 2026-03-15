.PHONY: plan apply clean

plan:
	terraform init
	terraform plan

apply:
	terraform init
	terraform apply

clean:
	rm -rf .terraform terraform.tfstate* .terraform.lock.hcl
