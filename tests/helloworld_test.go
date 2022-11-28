package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestHelloWorld(t *testing.T) {
	tfOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
	})

	defer terraform.Destroy(t, tfOpts)
	terraform.InitAndApply(t, tfOpts)

	output := terraform.Output(t, tfOpts, "hello_world")
	assert.Equal(t, output, "Hello, World!")
}
