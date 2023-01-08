package test

import (
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExampleLocalK8s(t *testing.T) {
	t.Parallel()

	tfOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/local-k8s",
	})
	defer terraform.Destroy(t, tfOpts)
	terraform.InitAndApply(t, tfOpts)
	outputs := terraform.OutputAll(t, tfOpts)

	// Test ingress accessible
	url := outputs["ingress"].(map[string]interface{})["http"].(string)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 30, 4*time.Second, func(status int, body string) bool {
		return status == 200
	})
}
