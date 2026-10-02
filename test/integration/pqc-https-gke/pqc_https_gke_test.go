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
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
)

func TestPqcHttpsGke(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		loadBalancerIp := bpt.GetStringOutput("load_balancer_ip")
		sslPolicyName := bpt.GetStringOutput("ssl_policy_name")
		projectId := bpt.GetStringOutput("project_id")

		fmt.Printf("Verifying SSL Policy %s in project %s\n", sslPolicyName, projectId)

		sslPolicyDescribe := gcloud.Run(t, "compute ssl-policies describe", gcloud.WithCommonArgs([]string{sslPolicyName, "--project", projectId, "--format", "json"}))

		pqcStatus := sslPolicyDescribe.Get("postQuantumKeyExchange").String()
		assert.Equal("ENABLED", pqcStatus, "Post-Quantum Key Exchange should be ENABLED on the SSL Policy")

		trimmedLoadBalancerIp := strings.TrimSpace(loadBalancerIp)

		var output []byte
		var err error

		isPqcSuccess := func() (bool, error) {
			dockerArgs := []string{"run", "--rm", "openquantumsafe/curl", "curl", "-v", "--tlsv1.3", "--tls-max", "1.3", "--curves", "X25519MLKEM768", "-k", "-I", fmt.Sprintf("https://%s.nip.io/assets/gcp-logo.svg", trimmedLoadBalancerIp)}
			cmd := exec.Command("docker", dockerArgs...)
			output, err = cmd.CombinedOutput()
			if err != nil {
				return true, err
			}
			return false, nil
		}

		utils.Poll(t, isPqcSuccess, 20, 15*time.Second)

		if assert.NoErrorf(err, "failed to negotiate TLS connection using openquantumsafe/curl for load balancer %s. Output: %s", loadBalancerIp, string(output)) {
			assert.Contains(string(output), "HTTP/1.1", "expected HTTP/1.1 from load balancer")
			assert.Contains(string(output), "200", "expected HTTP 200 OK from load balancer")
			assert.Contains(string(output), "SSL connection using TLSv1.3", "expected TLS 1.3")
		}

		fmt.Println("PQC infrastructure validation successful!")
	})

	bpt.Test()
}
