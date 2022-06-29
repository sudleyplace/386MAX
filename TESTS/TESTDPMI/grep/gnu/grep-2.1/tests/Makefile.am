## Process this file with automake to create Makefile.in

AWK=@AWK@

TESTS = khadafy.sh spencer1.sh spencer2.sh
EXTRA_DIST = $(TESTS) khadafy.lines khadafy.regexp \
             scriptgen.awk spencer1.tests spencer2.tests
CLEANFILES = tmp1.script tmp2.script khadafy.out
TESTS_ENVIRONMENT = GREP=$(top_builddir)/src/grep AWK=$(AWK)
