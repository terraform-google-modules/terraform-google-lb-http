package cloudrun

import (
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"

	test "github.com/terraform-google-modules/terraform-google-lb-http/test/integration"
)

func TestRedis(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		loadBalancerIp := bpt.GetStringOutput("load-balancer-ip")

		test.AssertResponseStatus(assert, "http://"+loadBalancerIp, 200)
	})

	bpt.Test()
}
