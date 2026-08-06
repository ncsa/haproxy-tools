BEGIN {
  # Define section using -v cmdline option
  if ( length( section ) < 1 ) {
    printf "Error, no section given on cmdline\n"
    exit
  }
  printok = 0
}
# skip comments outside of sections
/^#/ {next}
# start of a new section, stop printing
/^[a-z]/ { printok = 0 }
# if start of new section matching the one we're looking for, allow printing
/^[a-z]/ && $1 == section { printok = 1 }
printok == 1 { print }
