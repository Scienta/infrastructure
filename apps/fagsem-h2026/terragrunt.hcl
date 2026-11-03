include "root" {
  path = find_in_parent_folders("root.hcl")
}

# The harness's external secrets come from the operator's environment, so they
# never land in git. Empty values fail the variables' validation on plan.
inputs = {
  google_client_id     = get_env("GOOGLE_CLIENT_ID", "")
  google_client_secret = get_env("GOOGLE_CLIENT_SECRET", "")
  slack_webhook        = get_env("FAGDAG_SLACK_WEBHOOK", "")
}
