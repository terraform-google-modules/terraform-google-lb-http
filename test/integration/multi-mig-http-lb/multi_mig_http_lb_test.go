// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package multi_mig_http_lb_test

import (
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"

	test "github.com/terraform-google-modules/terraform-google-lb-http/test/integration"
)

func TestMultiMig(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	vars := map[string]interface{}{
		"network_prefix": "ci-lb-http-multi-mig-nat",
		"project":        bpt.GetTFSetupStringOutput("project_id"),
	}
	tft.WithVars(vars)(bpt)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		loadBalancerIp := bpt.GetStringOutput("load-balancer-ip")

		// Get "http://34.149.217.1": EOF
		test.AssertResponseStatus(t, assert, "http://"+loadBalancerIp, 200)
	})

	bpt.Test()
}
