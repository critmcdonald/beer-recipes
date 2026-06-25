#!/usr/bin/env Rscript
# render-recipes.R
# Renders a parameterized HTML page for every recipe in data-processed/recipes.xlsx
# using template-recipe.qmd, and writes output to _site/recipes/.
#
# Run this script whenever you update template-recipe.qmd to regenerate all pages:
#   source("R/render-recipes.R")
# Or from the shell:
#   Rscript R/render-recipes.R

# There was an AI note about a couple of recipes:
# Two recipes couldn't be matched to PDFs (the links simply won't appear for them):
#   
#   - Menchacaweizen Hefeweizen — the PDF is "SoCo Menchaca Hefeweizen", quite different
#   - SoCo English Export Imperial Stout — no clear PDF match found




library(tidyverse)
library(readxl)
library(quarto)

# ── Re-entry guard ────────────────────────────────────────────────────────────
# When this script calls quarto_render(), Quarto detects the project and would
# run post-render scripts again (including this one), causing an infinite loop.
# Setting this env var lets nested invocations bail out immediately.
if (identical(Sys.getenv("RECIPES_RENDERING"), "true")) {
  cat("render-recipes.R: skipping (already running)\n")
  quit(save = "no", status = 0)
}
Sys.setenv(RECIPES_RENDERING = "true")

# Clear Quarto's post-render env vars so inner quarto_render() calls behave
# like interactive calls and use project mode (shared site_libs, theme, etc.)
quarto_vars <- grep("^QUARTO_", names(Sys.getenv()), value = TRUE)
Sys.unsetenv(quarto_vars)

# ── Configuration ─────────────────────────────────────────────────────────────
# Specify which recipe IDs to render.
#   1:288  renders all recipes
#   1:3    renders only the first three
#   c(5, 12, 47)  renders specific IDs
recipe_ids <- 1:288

# ── Helpers ──────────────────────────────────────────────────────────────────

make_slug <- function(name) {
  name |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_remove_all("-+$") |>
    str_remove_all("^-+")
}

# ── Load data ─────────────────────────────────────────────────────────────────

recipes <- read_excel("data-processed/recipes.xlsx") |>
  select(id, recipe_name) |>
  filter(id %in% recipe_ids) |>
  mutate(slug = make_slug(recipe_name))

output_dir <- file.path("_site", "recipes")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Render each recipe ────────────────────────────────────────────────────────
# Template lives in recipes/ so Quarto outputs directly to _site/recipes/
# with correct relative paths to site_libs/ and styles.css — no moving needed.

n <- nrow(recipes)
cat(sprintf("Rendering %d recipe pages to %s/\n\n", n, output_dir))

for (i in seq_len(n)) {
  recipe_id   <- recipes$id[[i]]
  recipe_name <- recipes$recipe_name[[i]]
  slug        <- recipes$slug[[i]]
  output_file <- paste0(slug, ".html")

  cat(sprintf("[%d/%d] %s\n", i, n, recipe_name))

  quarto::quarto_render(
    input          = "recipes/template-recipe.qmd",
    output_format  = "html",
    output_file    = output_file,
    execute_params = list(recipe_id = as.integer(recipe_id)),
    quiet          = TRUE
  )
}

cat(sprintf("\nDone. %d pages written to %s/\n", n, output_dir))
