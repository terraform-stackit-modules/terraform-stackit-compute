package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesUpdate(t *testing.T) {

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/update",
		Vars: map[string]interface{}{
			"project_id": os.Getenv("STACKIT_PROJECT_ID"),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
