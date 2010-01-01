## Why is this folder here?

For now, all the specs that test live services go here.

Each of these tests is expected to make actual requests over the wire
to a remote service.

Specs that test our transport layer w/ mocks/recording etc should still go in spec/

(It is possible that we will write these tests to conditionally be live
or local, we will see.  In this case maybe all transport-related specs shouls go here)

It is assumed that these tests here won't be run as frequently
as those tests in spec, but they should still be run frequently enough to detect
api changes (such as they are) in the target services.

This folder, like everything else, is experimental.
