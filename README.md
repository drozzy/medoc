medoc
=====

Runs edoc on multiple apps and stitches the results together.

If you have an OTP layout like this:

foo/
  - apps/
    - bar1/
      - src/
    - bar2
      - src/

you can generate the edoc documentation for all your apps with `rebar3 medoc`.
The resulting html documention can be found under `foo/doc`:

foo/
  - doc/
    - index.html
    - bar1_app.html
    - bar2_app.html
    - ...

Description
------------
The regular `rebar3 edoc` command does not build the proper table of contents. This 
plugin fixes that, by first running edoc normally, and then rebuilding
the html table of contents in place.

To see what problem this solves, see https://github.com/erlang/rebar3/issues/1307
and http://stackoverflow.com/questions/39043889/rebar3-generate-edoc-for-multiple-apps


Use
---


Add the plugin to your rebar config:

    {plugins, [
        { medoc, ".*", {git, "git@github.com:drozzy/medoc.git", {tag, "1.0.0"}}}
    ]}.

Then just call your plugin directly in an existing application:


    $ rebar3 medoc

 Now you should be able to serve browse to `doc/index.html` and
 see your complete documentation.


Notes
------
This plugins modifies your edoc options, by setting it to be:

	{edoc_opts, [{dir, "doc"}]}.
