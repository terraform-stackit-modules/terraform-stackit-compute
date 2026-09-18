package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesServiceAccountAttach(t *testing.T) {

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/service-account-attach",
		Vars: map[string]interface{}{
			"project_id": os.Getenv("STACKIT_PROJECT_ID"),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
