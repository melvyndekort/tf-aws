.PHONY: init plan apply clean

ACCOUNT_ID := 844347863910
CURRENT_ACCOUNT := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)

# Backup and modify providers.tf based on current account
init:
	@if [ "$(CURRENT_ACCOUNT)" = "$(ACCOUNT_ID)" ]; then \
		echo "✓ In target account - using local credentials"; \
		cp providers.tf providers.tf.backup; \
		sed -i.tmp 's/assume_role {/# assume_role {/' providers.tf; \
		sed -i.tmp 's/role_arn =/# role_arn =/' providers.tf; \
		sed -i.tmp 's/^  }/  # }/' providers.tf; \
		rm -f providers.tf.tmp; \
	else \
		echo "✓ Different account - using providers.tf as-is"; \
	fi
	@terraform init

plan: init
	terraform plan

apply: init
	terraform apply

# Restore original providers.tf
restore:
	@if [ -f providers.tf.backup ]; then \
		mv providers.tf.backup providers.tf; \
		echo "✓ Restored original providers.tf"; \
	fi

clean: restore
	rm -rf .terraform terraform.tfstate* .terraform.lock.hcl providers.tf.backup providers.tf.tmp


