#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use ok 'B::Hooks::XSUB::CallAsOp';

B::Hooks::XSUB::CallAsOp::__test();

pass("returned");
