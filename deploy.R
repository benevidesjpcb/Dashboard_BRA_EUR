# ── Deploy to shinyapps.io ────────────────────────────────────────────────────
#
# Run this script once to publish the dashboard.
# Prerequisites:
#   1. Create a free account at https://www.shinyapps.io
#   2. Go to: Account > Tokens > Add Token > Show > Copy to Clipboard
#   3. Paste your credentials in the three fields below.
#
# After the first deploy the app URL will be:
#   https://<account>.shinyapps.io/Dashboard_BRA_EUR
# ------------------------------------------------------------------------------

library(rsconnect)

# ── Step 1: authenticate (run once, credentials are saved locally) ────────────
rsconnect::setAccountInfo(
  name   = "YOUR_ACCOUNT_NAME",   # shinyapps.io username
  token  = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)

# ── Step 2: deploy ────────────────────────────────────────────────────────────
rsconnect::deployApp(
  appDir      = ".",              # project root
  appName     = "Dashboard_BRA_EUR",
  appTitle    = "Brazil / Europe ANS Performance Dashboard",
  forceUpdate = TRUE
)

# After a successful deploy the URL is printed in the console and the browser
# opens automatically.
