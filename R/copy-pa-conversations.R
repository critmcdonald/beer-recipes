# Copy HTML files from pa-conversations/ into _site/pa-conversations/
src_dir <- "pa-conversations"
dest_dir <- file.path("_site", "pa-conversations")

if (dir.exists(src_dir)) {
  html_files <- list.files(src_dir, pattern = "\\.html$", full.names = TRUE)
  
  if (length(html_files) > 0) {
    if (!dir.exists(dest_dir)) {
      dir.create(dest_dir, recursive = TRUE)
    }
    
    copied <- file.copy(html_files, file.path(dest_dir, basename(html_files)), overwrite = TRUE)
    
    cat(sprintf("Copied %d HTML file(s) to '%s'\n", sum(copied), dest_dir))
  } else {
    cat(sprintf("No HTML files found in '%s'\n", src_dir))
  }
} else {
  cat(sprintf("Source directory '%s' does not exist\n", src_dir))
}