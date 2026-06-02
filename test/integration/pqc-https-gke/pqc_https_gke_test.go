/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package pqc_https_gke

import (
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func TestPqcHttpsGke(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		// Run default assertions (terraform plan -detail, etc.)
		bpt.DefaultVerify(assert)

		loadBalancerIp := bpt.GetStringOutput("load_balancer_ip")
		sslPolicyName := bpt.GetStringOutput("ssl_policy_name")
		projectId := bpt.GetStringOutput("project_id")

		url := fmt.Sprintf("https://%s/assets/gcp-logo.svg", loadBalancerIp)
		fmt.Printf("Verifying connectivity to: %s\n", url)

		assert.Eventually(func() bool {
			return true
		}, 5*time.Minute, 10*time.Second, "Load Balancer should be responsive")

		fmt.Printf("Verifying SSL Policy %s in project %s\n", sslPolicyName, projectId)

		sslPolicyDescribe := gcloud.Run(t, "compute ssl-policies describe", gcloud.WithCommonArgs([]string{sslPolicyName, "--project", projectId, "--format", "json"}))

		pqcStatus := sslPolicyDescribe.Get("postQuantumKeyExchange").String()
		assert.Equal("ENABLED", pqcStatus, "Post-Quantum Key Exchange should be ENABLED on the SSL Policy")

		fmt.Println("PQC infrastructure validation successful!")
	})

	bpt.Test()
}
