# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

control "https_patterns" do
  title "HTTPs Check region patterns"

  describe http("https://#{attribute("lb_ip")}/group1/",
                ssl_verify: false) do
	  its('body') { should match /.*#{attribute("group1_region")}/ }
  end
  describe http("https://#{attribute("lb_ip")}/group2/",
                ssl_verify: false) do
          its('body') { should match /.*#{attribute("group2_region")}/ }
  end
  describe http("https://#{attribute("lb_ip")}/group3/",
                ssl_verify: false) do
          its('body') { should match /.*#{attribute("group3_region")}/ }
  end
end
