use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Web/Weaver.pm';

use_ppport 3.19;
cc_warnings;

# requires ...

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Web-Weaver-* *.stackdump
    *.gcda *.gcno *.gcov
    nytprof *.out
    cover_db
);

WriteAll(check_nmake => 0);

