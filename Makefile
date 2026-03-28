.PHONY: help management account-% clean

# Default target
help:
	@echo "Terraform Management Commands"
	@echo ""
	@echo "Usage:"
	@echo "  make management [CMD]     - Run terraform in management account"
	@echo "  make account-NAME [CMD]   - Run terraform in subaccount"
	@echo ""
	@echo "Examples:"
	@echo "  make management plan"
	@echo "  make management apply"
	@echo "  make account-network-monitor plan"
	@echo "  make account-network-monitor apply"
	@echo ""
	@echo "Available accounts:"
	@cd accounts && ls -d */ 2>/dev/null | sed 's|/||' | sed 's/^/  - account-/'

# Management account operations
management:
	@cd management && terraform $(filter-out $@,$(MAKECMDGOALS))

# Subaccount operations with auto-detection
account-%:
	@ACCOUNT_NAME=$(subst account-,,$@); \
	ACCOUNT_DIR="accounts/$$ACCOUNT_NAME"; \
	if [ ! -d "$$ACCOUNT_DIR" ]; then \
		echo "Error: Account $$ACCOUNT_NAME not found"; \
		exit 1; \
	fi; \
	cd "$$ACCOUNT_DIR" && make $(filter-out $@,$(MAKECMDGOALS))

# Allow additional arguments to be passed through
%:
	@:

clean:
	@echo "Cleaning all terraform directories..."
	@cd management && rm -rf .terraform terraform.tfstate* .terraform.lock.hcl
	@for dir in accounts/*/; do \
		cd "$$dir" && rm -rf .terraform terraform.tfstate* .terraform.lock.hcl providers.tf.bak && cd ../..; \
	done
	@echo "Clean complete"

fmt:
	@terraform fmt management/
	@for dir in accounts/*/; do terraform fmt "$$dir"; done
	@for dir in modules/*/; do terraform fmt "$$dir"; done
