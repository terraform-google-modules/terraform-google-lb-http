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

package multiple_certs_test

import (
	"crypto/tls"
	"net/http"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"

	test "github.com/terraform-google-modules/terraform-google-lb-http/test/integration"
)

func TestMultipleCerts(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	vars := map[string]interface{}{
		"network_name": "ci-lb-http-multi-certs",
		"project":      bpt.GetTFSetupStringOutput("project_id"),
	}
	tft.WithVars(vars)(bpt)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		loadBalancerURL := "https://" + bpt.GetStringOutput("load-balancer-ip")

		insecureClient := &http.Client{Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}}

		// Check HTTPS
		test.AssertResponseStatusWithClient(t, assert, insecureClient, loadBalancerURL, 200)

		// Check asset URL
		test.AssertResponseStatusWithClient(t, assert, insecureClient, bpt.GetStringOutput("asset-url"), 200)

		{ // Check region patterns
			group1Region := bpt.GetStringOutput("group1_region")
			group2Region := bpt.GetStringOutput("group2_region")
			group3Region := bpt.GetStringOutput("group3_region")

			body1 := test.AssertResponseStatusWithClient(t, assert, insecureClient, loadBalancerURL+"/group1/", 200)
			assert.Regexp(group1Region+"$", body1)

			body2 := test.AssertResponseStatusWithClient(t, assert, insecureClient, loadBalancerURL+"/group2/", 200)
			assert.Regexp(group2Region+"$", body2)

			body3 := test.AssertResponseStatusWithClient(t, assert, insecureClient, loadBalancerURL+"/group3/", 200)
			assert.Regexp(group3Region+"$", body3)
		}
	})

	bpt.Test()
}
