1)  When you use the biblio, run bibtex with --min-crossrefs=1000
    to prevent it from getting overly clever and including the
    conference itself as a citation.  (Unless that's what you want,
    of course).

2)  Style issues:
    A great entry looks something like this:


    @inproceedings{joebob2020,
      author = "Joe Bob and Frank Bob",
      title = "Farming the River {S}tyx",
      crossref = "farmcon2020",
      pages = "155--166",
    }

    @proceedings{farmcon2020,
      booktitle = "Proc. {FARMCON}",
      year = 2020,
      month = may,
      address = "Styx, {HE}"
    }

    If the conference is a popular one, please split it out into
    a proceedings and an inproceedings.  Otherwise, leave them
    integrated as a single inproceedings.

     - Dates should be formatted using the bibtex macros
       (jan, feb, mar...)
       and the year without quoting, unless necessary
       (for things like "Winter 2002")

3) Canonical source vs. shortening

  The CVS biblio file is the canonical source of bibliography
  information.  Please do NOT commit destructive shortening tweaks into this
  file (like getting rid of the Address= info)!  
  Instead, copy the entries to a paper-specific .bib file
  and shorten them there.

  Because this is a canonical source, try to get as much information
  as possible - accurate addresses, page numbers, etc., to maximize
  the utility of the bibliography.


4) Validate before commit

  Please use the scripts in the test/ directory to validate the
  bib file before you commit your changes.  This will help ensure
  both style compliance and that the changes don't inadvertently
  break other parts of the build file.  Watch the bibtex output
  for warnings -- see "test.blg".  Watch the latex output for
  missing references and/or gross errors.

5) Naming and positioning

  Try to stick with a naming convention similar to current
  entries, and when you insert new items into the bib, insert them
  alphabetically.
