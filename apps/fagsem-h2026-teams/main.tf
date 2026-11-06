# Fagsem H2026: one project per team (./team), each with its own registry,
# container, database and read-only logs token. The harness is in
# ../fagsem-h2026.
#
# Bring-up runs in two phases, because a container can't start before an
# image is in its registry:
#
#   1. Everything but the containers, so the registries and push keys exist:
#
#        args=()
#        for slug in team-1 team-2 team-3 team-4 team-5 team-6 team-7 team-8 team-9; do
#          args+=("-exclude=module.team[\"$slug\"].module.app.scaleway_container.main")
#        done
#        terragrunt run -- apply "${args[@]}"
#
#      Keep the loop and local.registries in step with local.slugs. Then push the template image
#      to every team's registry as app:latest, with the keys from
#
#        (umask 077; terragrunt output -json registries > team-registries.json)
#
#      The teams output isn't there yet: it holds the container IDs, so
#      -exclude leaves it out.
#   2. terragrunt apply
#      creates the containers, then the CNAMEs and the custom domains.
#
# The operator hands the keys and URLs to the team repos with
#
#   (umask 077; terragrunt output -json teams > team-outputs.json)
#
# Reset one team's database (a new, empty one; the container is redeployed
# with the new PG* values):
#
#   terragrunt run -- apply -replace='module.team["<slug>"].module.app.scaleway_sdb_sql_database.main["enabled"]'

locals {
  slugs = toset([
    "team-1",
    "team-2",
    "team-3",
    "team-4",
    "team-5",
    "team-6",
    "team-7",
    "team-8",
    "team-9",
    "team-11",
  ])

  # 1 keeps every team warm, at the cost of paying for idle containers
  team_min_scale = 0
}

module "team" {
  source   = "./team"
  for_each = local.slugs

  slug      = each.key
  min_scale = local.team_min_scale
}

output "teams" {
  value     = { for slug, team in module.team : slug => team.team }
  sensitive = true
}

# The registry part of teams, for seeding the images between the phases.
# The references are static on purpose: module.team[slug] with a computed
# slug depends on all of module.team, so -exclude would drop this output too.
locals {
  registries = {
    "team-1"  = module.team["team-1"].registry
    "team-2"  = module.team["team-2"].registry
    "team-3"  = module.team["team-3"].registry
    "team-4"  = module.team["team-4"].registry
    "team-5"  = module.team["team-5"].registry
    "team-6"  = module.team["team-6"].registry
    "team-7"  = module.team["team-7"].registry
    "team-8"  = module.team["team-8"].registry
    "team-9"  = module.team["team-9"].registry
    "team-11" = module.team["team-11"].registry
  }
}

output "registries" {
  value     = local.registries
  sensitive = true

  precondition {
    condition     = toset(keys(local.registries)) == local.slugs
    error_message = "local.registries must list exactly the slugs in local.slugs."
  }
}
